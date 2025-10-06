String mapFirebaseErrorCode(String code) {
  switch (code) {
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'auth_error_invalid_credentials';
    case 'email-already-in-use':
      return 'auth_error_email_in_use';
    case 'requires-recent-login':
    case 'wrong-password-change':
    case 'wrong-password-delete':
      return 'auth_error_wrong_password';
    default:
      return 'auth_error_general';
  }
}