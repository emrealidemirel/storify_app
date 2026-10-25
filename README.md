# Storify

Storify is a Flutter application for interactive fiction in Turkish and English. Readers choose a genre and protagonist, then guide the story through branching choices. Registered users can generate stories with AI; guests can explore prewritten stories without making AI requests.

The primary targets are Android and iOS. Desktop and web project files are included, but their presence does not imply production support or equivalent validation.

## Project status

The application is under active development. Local tests and unsigned Android/iOS release builds have passed, but **the current implementation is not ready for public distribution**.

AI generation and moderation currently call OpenAI directly using a development key bundled in `.env`. Before distribution, these requests must move to an authenticated backend with server-side credentials, quotas and usage limits. Production signing, provider configuration, live Storage rules and public privacy/account-deletion pages also remain to be completed.

See [release preparation](docs/release_preparation.md) for completed work, validation results and the remaining release checklist. The [initial audit](docs/release_readiness_audit_2026-10-24.md) is retained as a historical record, not the current status.

## Features

### Stories

- AI-generated stories using `gpt-4o-mini`, with three choices per passage.
- Prompts that preserve story context and the consequences of previous choices.
- Duplicate-text and duplicate-choice detection, with one automatic revision attempt.
- Generated text and choices checked with `omni-moderation-latest` before display. Failed checks prevent the passage from being displayed.
- AI sessions limited to 30 passages, with a concluding-passage instruction.
- Eight prewritten guest story themes in each language, with five continuation steps and branching endings.
- Local persistence of the latest AI story, associated with its account.
- Existing story text remains visible while the next passage loads.

Guest stories are bundled assets. **The first guest sign-in still requires internet access**, because guest sessions use Firebase anonymous authentication.

### Accounts and privacy

- Email/password, Google and anonymous sign-in through Firebase Authentication.
- Sign in with Apple implementation for iOS; Apple Developer and Firebase provider configuration is required before use.
- Password reset, password/email changes, an email-verification link action and optional profile name/photo updates.
- Profile image size/type checks and upload to Firebase Storage.
- Reauthentication before account deletion, followed by associated file and local-data cleanup before the Firebase Auth account is removed.
- Turkish and English privacy information, account-specific AI sharing permission and an option to withdraw it.
- In-app story reporting. Reports contain the story, choices and selected reason and are stored under the user's Firebase Storage path for developer review. No automatic email notification or moderation dashboard is included.

### Interface

- Light and dark themes using the application's brown and gold palette.
- Turkish and English localization.
- Responsive layouts, bundled fonts and theme-aware loading indicators.
- Retry and error states for startup and story requests.

Premium subscriptions, purchases, advertising and analytics integrations are **not implemented**.

## Architecture

The app uses Bloc/Cubit for state management and follows a layered directory structure:

```text
lib/
  blocs/          Authentication, story and theme state
  constants/      Routes and public release configuration
  models/         Story data models and validation
  pages/          Application screens
  repositories/   Authentication contract and story repositories
  services/       Firebase, preferences, prompts and content safety
  theme/          Shared visual theme
  utils/          Environment parsing and authentication error mapping
  widgets/        Reusable UI components
assets/
  fonts/          Bundled fonts and their licenses
  images/         Application artwork and icons
  langs/          Turkish and English translations
  stories/        Prewritten guest story graphs
test/            Flutter unit and widget tests
tool/firebase_tests/
                  Firebase Storage security-rule tests
docs/            Audit and release preparation notes
```

Firebase Authentication manages accounts. Firebase Storage holds profile images and content reports. Story progress and preferences are stored locally using SharedPreferences. There is currently no server component in this repository for AI requests or billing enforcement.

## Local development

### Requirements

- Flutter with its bundled Dart SDK. `pubspec.yaml` declares Dart `^3.7.0`; use a Flutter version compatible with the locked dependencies.
- Android SDK 36, NDK `28.2.13676358` and a compatible Java/Gradle environment for Android.
- macOS and Xcode for iOS. The Apple projects use Swift Package Manager for Flutter plugins.
- A Firebase project configured for the platforms and authentication providers being tested.
- An OpenAI API project with access to the generation and moderation models for AI functionality.

### Installation

```sh
git clone https://github.com/emrealidemirel/storify_app.git
cd storify_app
flutter pub get
cp .env.example .env
```

Set your development key in the local `.env` file:

```dotenv
GPT_TOKEN=YOUR_DEVELOPMENT_KEY
```

`OPENAI_API_KEY` is also accepted. The environment parser supports either dotenv syntax or a JSON object with one of these keys. A nonempty `GPT_TOKEN` takes precedence.

`.env` is excluded from Git, but Flutter currently includes it in application assets. **Git exclusion does not protect a key inside an installed app.** Do not distribute these development builds. Stop and restart the app after changing `.env`; hot reload may retain the old bundled asset.

### Firebase configuration

For your own deployment, regenerate Firebase configuration with FlutterFire CLI rather than relying on this repository's existing project identifiers:

```sh
flutterfire configure
```

Enable the relevant sign-in providers in Firebase. Configure Google OAuth for the chosen application identifiers and signing certificates. For Apple sign-in, configure the Apple provider and Sign in with Apple capability. Verify generated file locations against the native projects before building.

`storage.rules` defines ownership, file-size and MIME checks for profile images and reports. The rules have been tested locally; **they have not been deployed to the live project as part of release preparation**. Review existing rules and deploy to the intended project before relying on the new upload, reporting and deletion flows.

```sh
flutter run
```

## Testing

```sh
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed lib test
```

The Flutter suite covers story context, repetition handling, authored story paths, loading behavior, account layouts and selected security/failure scenarios. Mocked tests do not validate real provider configuration or live Firebase permissions.

Storage-rule tests require Node.js 20 or later, Java 21 and Firebase CLI installed on your path:

```sh
cd tool/firebase_tests
npm ci
npm test
```

These tests use the local Storage emulator and the `demo-storify` project. They do not deploy rules or access production data.

The last recorded validation includes **72 passing Flutter tests**, **18 passing Storage-rule checks**, clean Flutter analysis and successful unsigned Android/iOS release builds. Signed device testing and store validation remain outstanding.

## Build and release configuration

```sh
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Android release builds are unsigned unless `android/key.properties` is configured. Use `android/key.properties.example` as a template and keep passwords and keystores out of version control. The iOS command explicitly skips signing and does not produce a validated App Store submission.

Public deployment metadata can be supplied with `--dart-define-from-file` using these keys:

| Key | Purpose |
| --- | --- |
| `PUBLISHER_NAME` | Publisher name shown in privacy information |
| `SUPPORT_EMAIL` | Support contact |
| `PRIVACY_URL` | HTTPS privacy policy URL |
| `ACCOUNT_DELETION_URL` | HTTPS external account-deletion request URL |

These values are intentionally unset pending release planning. Do not place API secrets in Dart defines. Default application identifiers remain unchanged to preserve the existing Firebase setup; choose final identifiers and update provider configuration together before release.

Gradle/Kotlin forward-compatibility warnings remain documented in the release checklist. A successful build with the current toolchain does not guarantee compatibility with future Flutter versions.

## Release boundaries

Before public distribution:

1. Move AI generation and moderation to an authenticated backend; remove the bundled key and implement server-side usage controls.
2. Configure final identifiers, signing credentials and Google/Apple authentication.
3. Review and deploy Storage rules, and test upload, reporting and deletion against real accounts.
4. Publish privacy and account-deletion pages and provide the actual publisher/support details.
5. Verify privacy disclosures, age ratings, provider data handling and the final signed archive.
6. Complete real-device testing and store validation.

No deployment, store upload or public release is performed by the build commands above. Bundled font licenses are included in `assets/fonts/` and registered in the application's license screen.
