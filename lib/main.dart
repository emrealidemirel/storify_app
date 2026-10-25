import 'package:flutter_story_app/pages/startup_error_page.dart';
import 'package:flutter_story_app/blocs/auth/auth_state.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/firebase_options.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/services/firebase_auth_service.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:flutter_story_app/theme/app_theme.dart';
import 'package:flutter_story_app/utils/environment_parser.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    for (final font in ['Lora', 'NunitoSans', 'Cinzel']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
  });
  await _launch();
}

Future<void> _launch() async {
  try {
    await _initialize();
  } catch (_) {
    // Never expose initialization exceptions: provider messages can contain secrets.
    runApp(StartupErrorApp(retry: _launch));
  }
}

Future<void> _initialize() async {
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env", parser: const EnvironmentParser());
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String? languageCode = await PreferencesService.getLanguageCode();
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;

  String initialRoute = isLoggedIn ? Routes.home : Routes.signIn;

  if (languageCode == null) {
    Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    languageCode = deviceLocale.languageCode == 'tr' ? 'tr' : 'en';
    await PreferencesService.saveLanguageCode(languageCode);
  } else if (languageCode != 'tr' && languageCode != 'en') {
    languageCode = 'en';
    await PreferencesService.saveLanguageCode(languageCode);
  }

  runApp(
    EasyLocalization(
      supportedLocales: [Locale("en", "US"), Locale("tr", "TR")],
      path: "assets/langs",
      fallbackLocale: Locale("en", "US"),
      child: ResponsiveSizer(
        builder: (context, orientation, screenType) {
          return MyApp(languageCode: languageCode, initialRoute: initialRoute);
        },
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final String? languageCode;
  final String initialRoute;
  const MyApp({
    super.key,
    required this.languageCode,
    required this.initialRoute,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) => StoryCubit(
                storyRepository: StoryRepository(
                  canUseAI: () {
                    final user = FirebaseAuth.instance.currentUser;
                    return user != null && !user.isAnonymous;
                  },
                ),
                aiUserId: () {
                  final user = FirebaseAuth.instance.currentUser;
                  return user != null && !user.isAnonymous ? user.uid : null;
                },
                languageCode: languageCode ?? "en",
              ),
        ),
        BlocProvider(
          create:
              (context) =>
                  AuthCubit(authRepository: FirebaseAuthService())
                    ..checkAuthStatus(),
        ),
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen:
            (previous, current) =>
                current is AuthUnauthenticated ||
                current is AuthLoggedOut ||
                (current is AuthAuthenticated &&
                    (previous is! AuthAuthenticated ||
                        previous.user.uid != current.user.uid)),
        listener: (context, state) => context.read<StoryCubit>().clearSession(),
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              theme: AppTheme.lightTheme(context),
              darkTheme: AppTheme.darkTheme(context),
              themeMode: themeState.themeMode,
              debugShowCheckedModeBanner: false,
              initialRoute: initialRoute,
              routes: Routes.getRoutes(),
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
            );
          },
        ),
      ),
    );
  }
}
