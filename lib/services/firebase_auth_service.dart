import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  User? getCurrentUser() => _auth.currentUser;

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'google-signin-cancelled');
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
      await _auth.signOut();
      await _googleSignIn.signOut();
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

  Future<void> updateProfilePhoto(String downloadUrl) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePhotoURL(downloadUrl);
      await user.reload();
    }
  }

  @override
  Future<void> verifyAndUpdateEmail(String newEmail, String currentPassword) async {
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
      throw FirebaseAuthException(code: 'auth_error_general', message: 'Beklenmeyen bir hata oluştu');
    }
  }

  @override
  Future<void> updatePassword(String currentPassword, String newPassword) async {
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
      throw FirebaseAuthException(code: 'auth_error_general', message: 'Beklenmeyen bir hata oluştu');
    }
  }

  @override
  Future<void> deleteAccount([String? currentPassword]) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'no-user');

    try {
      final provider = user.providerData.first.providerId;

      if (provider == 'password') {
        if (currentPassword == null || currentPassword.isEmpty) {
          throw FirebaseAuthException(code: 'missing-password');
        }

        final cred = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );

        await user.reauthenticateWithCredential(cred);
      }

      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthException(code: e.code, message: e.message);
    } catch (_) {
      throw FirebaseAuthException(code: 'auth_error_general', message: 'Beklenmeyen bir hata oluştu');
    }
  }
}