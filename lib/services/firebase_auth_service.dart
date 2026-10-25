import 'dart:io';
import 'package:flutter_story_app/services/firebase_storage_service.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseStorageService _storage;

  FirebaseAuthService({FirebaseAuth? auth, FirebaseStorageService? storage})
    : _auth = auth ?? FirebaseAuth.instance,
      _storage = storage ?? FirebaseStorageService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  User? getCurrentUser() => _auth.currentUser;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_google_signin_failed');
    }
  }

  @override
  Future<User?> signInWithApple() async {
    try {
      return (await _auth.signInWithProvider(AppleAuthProvider())).user;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'canceled' || error.code == 'web-context-cancelled') {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseAuthException(code: 'no-user');
    }
    if (!user.emailVerified) await user.sendEmailVerification();
  }

  @override
  Future<void> updateProfile({String? displayName, File? image}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      throw FirebaseAuthException(code: 'no-user');
    }
    if (displayName != null) await user.updateDisplayName(displayName);
    if (image != null) {
      final url = await _storage.uploadProfileImage(image, user.uid);
      await user.updatePhotoURL(url);
    }
    await user.reload();
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_email_signin_failed');
    }
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_signup_failed');
    }
  }

  @override
  Future<User?> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      return result.user;
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_anonymous_signin_failed');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Firebase sign-out still needs to complete if Google cache cleanup fails.
      }
      await _auth.signOut();
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_signout_failed');
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      rethrow;
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_password_reset_failed');
    }
  }

  @override
  Future<void> verifyAndUpdateEmail(
    String newEmail,
    String currentPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user');

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.verifyBeforeUpdateEmail(newEmail);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (_) {
      throw FirebaseAuthException(
        code: 'auth_error_general',
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  @override
  Future<void> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user');

    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      await user.reload();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (_) {
      throw FirebaseAuthException(
        code: 'auth_error_general',
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }

  @override
  Future<void> deleteAccount([String? currentPassword]) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user');

    try {
      final providers =
          user.providerData.map((data) => data.providerId).toSet();

      if (providers.contains('password')) {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw FirebaseAuthException(code: 'missing-password');
        }
        final email = user.email;
        if (email == null || email.isEmpty) {
          throw FirebaseAuthException(code: 'invalid-email');
        }

        final cred = EmailAuthProvider.credential(
          email: email,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(cred);
      } else if (providers.contains('google.com')) {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw FirebaseAuthException(code: 'reauthentication-required');
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
      } else if (providers.contains('apple.com')) {
        final result = await user.reauthenticateWithProvider(
          AppleAuthProvider(),
        );
        final authorizationCode = result.additionalUserInfo?.authorizationCode;
        if (authorizationCode == null || authorizationCode.isEmpty) {
          throw FirebaseAuthException(code: 'reauthentication-required');
        }
        await _auth.revokeTokenWithAuthorizationCode(authorizationCode);
      }

      // Delete while the user still has permission. A failed cleanup must not
      // turn into a misleading successful account deletion; retry is safe.
      await _storage.deleteUserData(user.uid);
      await PreferencesService.clearUserData();
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (_) {
      throw FirebaseAuthException(
        code: 'auth_error_general',
        message: 'Beklenmeyen bir hata oluştu',
      );
    }
  }
}
