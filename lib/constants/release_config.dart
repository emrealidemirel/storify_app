/// Public deployment metadata. Supply real values with --dart-define-from-file.
/// Never put provider secrets here.
class ReleaseConfig {
  static const publisher = String.fromEnvironment('PUBLISHER_NAME');
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
  static const privacyUrl = String.fromEnvironment('PRIVACY_URL');
  static const deletionUrl = String.fromEnvironment('ACCOUNT_DELETION_URL');
}
