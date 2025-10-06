import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_state.dart';
import 'package:flutter_story_app/utils/auth_utils.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository authRepository;

  AuthCubit({required this.authRepository}) : super(AuthInitial());

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithGoogle();
      if (user != null) {
        await PreferencesService.saveLoginStatus(true);
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthError('auth_error_google_signin_failed'.tr()));
      }
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(AuthLoading());
    try {
      final user = await authRepository.signInWithEmail(email, password);
      if (user != null) {
        await PreferencesService.saveLoginStatus(true);
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
        await PreferencesService.saveLoginStatus(true);
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
        await PreferencesService.saveLoginStatus(true);
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

  Future<void> signOut() async {
    await PreferencesService.saveLoginStatus(false);
    try {
      await authRepository.signOut();
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthError('auth_error_signout_failed'.tr()));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(AuthLoading());
    try {
      await authRepository.sendPasswordResetEmail(email);
      emit(AuthPasswordResetEmailSent());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_password_reset_failed'.tr()));
    }
  }

  Future<void> checkAuthStatus() async {
    final user = authRepository.getCurrentUser();
    if (user != null) {
      await PreferencesService.saveLoginStatus(true);
      emit(AuthAuthenticated(user));
    } else {
      await PreferencesService.saveLoginStatus(false);
      emit(AuthUnauthenticated());
    }
  }

  Future<void> changeEmail(String newEmail, String currentPassword) async {
    emit(AuthLoading());
    try {
      await authRepository.verifyAndUpdateEmail(newEmail, currentPassword);
      final user = authRepository.getCurrentUser();
      await user?.reload();
      emit(AuthAuthenticated(user!));
      emit(AuthEmailChangeInitiated());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    emit(AuthLoading());
    try {
      await authRepository.updatePassword(currentPassword, newPassword);
      final user = authRepository.getCurrentUser();
      await user?.reload();
      emit(AuthAuthenticated(user!));
      emit(AuthPasswordChanged());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }

  Future<void> deleteAccount([String? currentPassword]) async {
    emit(AuthLoading());
    try {
      await authRepository.deleteAccount(currentPassword);
      emit(AuthLoggedOut());
    } on FirebaseAuthException catch (e) {
      emit(AuthError(mapFirebaseErrorCode(e.code).tr()));
    } catch (_) {
      emit(AuthError('auth_error_general'.tr()));
    }
  }
}
