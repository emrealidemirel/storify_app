String mapFirebaseErrorCode(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'invalid-login-credentials':
    case 'user-not-found':
    case 'wrong-password':
      return 'auth_error_invalid_credentials';
    case 'email-already-in-use':
      return 'auth_error_email_in_use';
    case 'wrong-password-change':
    case 'wrong-password-delete':
      return 'auth_error_wrong_password';
    case 'requires-recent-login':
    case 'reauthentication-required':
      return 'auth_error_reauthentication_required';
    case 'user-disabled':
      return 'auth_error_user_disabled';
    case 'weak-password':
      return 'auth_error_weak_password';
    case 'operation-not-allowed':
      return 'auth_error_operation_not_allowed';
    case 'too-many-requests':
      return 'auth_error_too_many_requests';
    case 'network-request-failed':
      return 'auth_error_network';
    case 'auth_error_google_signin_failed':
    case 'auth_error_email_signin_failed':
    case 'auth_error_signup_failed':
    case 'auth_error_anonymous_signin_failed':
    case 'auth_error_password_reset_failed':
    case 'auth_error_signout_failed':
      return code;
    default:
      return 'auth_error_general';
  }
}
