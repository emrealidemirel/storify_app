import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';
import 'package:flutter_story_app/utils/auth_utils.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;
  int _passwordResetRequestId = 0;
  int? _activePasswordResetRequestId;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  String _errorMessage(
    FirebaseAuthException error, {
    bool reauthentication = false,
  }) {
    final isWrongCurrentPassword =
        reauthentication &&
        (error.code == 'wrong-password' || error.code == 'invalid-credential');
    return (isWrongCurrentPassword
            ? 'auth_error_wrong_password'
            : mapFirebaseErrorCode(error.code))
        .tr();
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> signInWithApple() async {
    if (state is AuthLoading) return;
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithApple();
      if (!isClosed) {
        emit(user == null ? AuthUnauthenticated() : AuthAuthenticated(user));
      }
    } on FirebaseAuthException catch (e) {
      if (!isClosed) emit(AuthError(_errorMessage(e)));
    } catch (_) {
      if (!isClosed) emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> updateProfile({String? displayName, File? image}) async {
    await authRepository.updateProfile(displayName: displayName, image: image);
    if (!isClosed) await checkAuthStatus();
  }

  Future<void> sendEmailVerification() =>
      authRepository.sendEmailVerification();

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmail(email, password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('auth_error_email_signin_failed'.tr()));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signUpWithEmail(email, password);
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('auth_error_signup_failed'.tr()));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> signInAnonymously() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInAnonymously();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('auth_error_anonymous_signin_failed'.tr()));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<bool> signOut() async {
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
      return true;
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
      return false;
    } catch (_) {
      emit(AuthError('auth_error_signout_failed'.tr()));
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    final requestId = ++_passwordResetRequestId;
    _activePasswordResetRequestId = requestId;
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(email);
      if (isClosed || _activePasswordResetRequestId != requestId) return;
      _activePasswordResetRequestId = null;
      emit(AuthPasswordResetEmailSent());
    } on FirebaseAuthException catch (e) {
      if (isClosed || _activePasswordResetRequestId != requestId) return;
      _activePasswordResetRequestId = null;
      emit(AuthPasswordResetError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      if (isClosed || _activePasswordResetRequestId != requestId) return;
      _activePasswordResetRequestId = null;
      emit(AuthPasswordResetError('auth_error_password_reset_failed'.tr()));
    }
  }

  void cancelPasswordReset() {
    final hasResetError = state is AuthPasswordResetError;
    if (_activePasswordResetRequestId == null && !hasResetError) return;

    _passwordResetRequestId++;
    _activePasswordResetRequestId = null;
    emit(AuthUnauthenticated());
  }

  Future<void> checkAuthStatus() async {
    final user = authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<bool> changeEmail(String newEmail, String currentPassword) async {
    emit(AuthLoading());
    try {
      await authRepository.verifyAndUpdateEmail(newEmail, currentPassword);
      final user = authRepository.getCurrentUser();
      await user?.reload();
      emit(AuthAuthenticated(user!));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_errorMessage(e, reauthentication: true)));
      return false;
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
      return false;
    }
  }

  Future<bool> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.updatePassword(currentPassword, newPassword);
      final user = authRepository.getCurrentUser();
      await user?.reload();
      emit(AuthAuthenticated(user!));
      return true;
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_errorMessage(e, reauthentication: true)));
      return false;
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
      return false;
    }
  }

  Future<bool> deleteAccount([String? currentPassword]) async {
    emit(AuthLoading());
    try {
      await authRepository.deleteAccount(currentPassword);
      emit(AuthLoggedOut());
      return true;
    } on FirebaseAuthException catch (e) {
      emit(AuthError(_errorMessage(e, reauthentication: true)));
      return false;
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
      return false;
    }
  }
}
