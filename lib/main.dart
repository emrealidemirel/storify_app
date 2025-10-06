import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/story/story_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_state.dart';
import 'package:flutter_story_app/contants/routes.dart';
import 'package:flutter_story_app/firebase_options.dart';
import 'package:flutter_story_app/repositories/story_repository.dart';
import 'package:flutter_story_app/services/firebase_auth_service.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:flutter_story_app/theme/app_theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  String? languageCode = await PreferencesService.getLanguageCode();
  bool isLoggedIn = await PreferencesService.getLoginStatus();

  String initialRoute = isLoggedIn ? Routes.home : Routes.signIn;

  if (languageCode == null) {
    Locale deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    languageCode = deviceLocale.languageCode;
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
                storyRepository: StoryRepository(),
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
    );
  }
}
