import 'package:flutter_story_app/pages/sign_in_page.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/auth/auth_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_cubit.dart';
import 'package:flutter_story_app/blocs/theme/theme_state.dart';
import 'package:flutter_story_app/constants/routes.dart';
import 'package:flutter_story_app/pages/settings_page.dart';
import 'package:flutter_story_app/repositories/auth_repository.dart';
import 'package:flutter_story_app/theme/app_theme.dart';
import 'package:flutter_story_app/widgets/app_drawer.dart';
import 'package:flutter_story_app/widgets/account_widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _User extends Fake implements User {
  final String provider;
  _User(this.provider);
  @override
  bool get isAnonymous => provider == 'guest';
  @override
  String? get displayName => isAnonymous ? null : 'Deniz Hikâye Gezgini';
  @override
  String? get email => isAnonymous ? null : 'deniz.uzun.bir.eposta@example.com';
  @override
  String? get photoURL => null;
  @override
  List<UserInfo> get providerData => isAnonymous ? [] : [_Info(provider)];
}

class _Info extends Fake implements UserInfo {
  @override
  final String providerId;
  _Info(this.providerId);
}

class _Repository extends Fake implements AuthRepository {
  final User user;
  _Repository(this.user);
  @override
  User? getCurrentUser() => user;
}

class _Translations extends AssetLoader {
  const _Translations();
  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(
            File(
              '$path/${locale.languageCode}-${locale.countryCode}.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
    for (final font in ['Lora', 'NunitoSans', 'Cinzel', 'MaterialIcons']) {
      await (FontLoader(font)..addFont(
        rootBundle.load(
          font == 'MaterialIcons'
              ? 'fonts/MaterialIcons-Regular.otf'
              : 'assets/fonts/$font.ttf',
        ),
      )).load();
    }
  });

  Future<void> mount(
    WidgetTester tester, {
    String provider = 'guest',
    Size size = const Size(430, 932),
    double scale = 1,
    bool dark = false,
    bool drawer = false,
    bool signIn = false,
  }) async {
    SharedPreferences.setMockInitialValues({'isDarkMode': dark});
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    final auth = AuthCubit(authRepository: _Repository(_User(provider)));
    await auth.checkAuthStatus();
    final theme = ThemeCubit();
    addTearDown(auth.close);
    addTearDown(theme.close);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        startLocale: const Locale('tr', 'TR'),
        saveLocale: false,
        path: 'assets/langs',
        assetLoader: const _Translations(),
        child: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: auth),
            BlocProvider.value(value: theme),
          ],
          child: Builder(
            builder:
                (context) => BlocBuilder<ThemeCubit, ThemeState>(
                  builder:
                      (context, state) => MaterialApp(
                        locale: context.locale,
                        supportedLocales: context.supportedLocales,
                        localizationsDelegates: context.localizationDelegates,
                        theme:
                            state.themeMode == ThemeMode.dark
                                ? AppTheme.darkTheme(context)
                                : AppTheme.lightTheme(context),
                        builder:
                            (context, child) => MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(textScaler: TextScaler.linear(scale)),
                              child: RepaintBoundary(
                                key: const ValueKey('account-preview'),
                                child: child!,
                              ),
                            ),
                        routes: {
                          Routes.home:
                              (_) => const Scaffold(
                                body: Text('Home destination'),
                              ),
                          Routes.signIn:
                              (_) => const Scaffold(
                                body: Text('Sign-in destination'),
                              ),
                        },
                        home:
                            signIn
                                ? const SignInPage()
                                : drawer
                                ? Scaffold(
                                  appBar: AppBar(),
                                  drawer: const AppDrawer(),
                                  body: const Text('Test home'),
                                )
                                : const SettingsPage(),
                      ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (drawer) {
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
    }
  }

  for (final provider in ['guest', 'password', 'google.com']) {
    for (final dark in [false, true]) {
      testWidgets(
        '$provider settings fit small screens at 2x text dark=$dark',
        (tester) async {
          await mount(
            tester,
            provider: provider,
            size: const Size(320, 568),
            scale: 2,
            dark: dark,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('Dil'), findsNothing);
          expect(find.text('Görünüm'), findsNothing);
          if (provider == 'password') {
            await tester.scrollUntilVisible(
              find.text('Şifre Değiştir').hitTestable(),
              100,
            );
            await tester.pumpAndSettle();
            expect(find.text('Şifre Değiştir').hitTestable(), findsOneWidget);
          } else {
            expect(find.text('Şifre Değiştir'), findsNothing);
          }
          await tester.scrollUntilVisible(find.text('Uygulama hakkında'), 200);
          expect(tester.takeException(), isNull);
          if (provider != 'guest') {
            await tester.scrollUntilVisible(find.text('Hesabı Sil'), 200);
            expect(find.text('Hesabı Sil').hitTestable(), findsOneWidget);
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'drawer fits small screen, keeps preferences and navigates home',
    (tester) async {
      await mount(tester, drawer: true, size: const Size(320, 568), scale: 2);
      await tester.scrollUntilVisible(
        find.byType(Switch),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('Karanlık Tema'), findsOneWidget);
      expect(
        (await SharedPreferences.getInstance()).getBool('isDarkMode'),
        isTrue,
      );
      await tester.scrollUntilVisible(
        find.text('Ana Sayfa'),
        -250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Ana Sayfa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ana Sayfa'));
      await tester.pumpAndSettle();
      expect(find.text('Home destination'), findsOneWidget);
    },
  );

  testWidgets('drawer language selection updates and persists locale', (
    tester,
  ) async {
    await mount(tester, drawer: true);
    await tester.scrollUntilVisible(
      find.text('Dil'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Dil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(
      (await SharedPreferences.getInstance()).getString('languageCode'),
      'en',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel reset preserves current screen without calling story service',
    (tester) async {
      await mount(tester, drawer: true);
      await tester.scrollUntilVisible(
        find.text('Hikâyeyi sıfırla'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Hikâyeyi sıfırla'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('İptal'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AppDrawer), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'about information opens at large text without changing account',
    (tester) async {
      await mount(tester, size: const Size(320, 568), scale: 2, dark: true);
      await tester.scrollUntilVisible(find.text('Uygulama hakkında'), 250);
      await tester.ensureVisible(find.text('Uygulama hakkında'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Uygulama hakkında'));
      await tester.pumpAndSettle();
      expect(find.byType(AboutDialog), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'login fields match and keyboard layout fits dark=$dark scale=$scale',
        (tester) async {
          await mount(
            tester,
            signIn: true,
            dark: dark,
            scale: scale,
            size: const Size(320, 568),
          );
          final fields = find.byType(TextFormField);
          expect(fields, findsNWidgets(2));
          expect(tester.getSize(fields.at(0)), tester.getSize(fields.at(1)));
          expect(tester.takeException(), isNull);
          tester.view.viewInsets = const FakeViewPadding(bottom: 220);
          addTearDown(tester.view.resetViewInsets);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Misafir olarak keşfet'));
          await tester.pumpAndSettle();
          expect(
            find.text('Misafir olarak keşfet').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('login preview', (tester) async {
    await mount(tester, signIn: true, size: const Size(430, 1100));
    if (Platform.environment['CAPTURE_UI'] == '1') {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('account-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1.5);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          'build/ui-preview/login.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });

  for (final drawer in [false, true]) {
    testWidgets('capture account preview drawer=$drawer', (tester) async {
      await mount(
        tester,
        provider: 'password',
        drawer: drawer,
        size: Size(drawer ? 430 : 768, 1400),
      );
      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_UI'] == '1') {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('account-preview')),
        );
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1.5);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          Directory('build/ui-preview').createSync(recursive: true);
          File(
            'build/ui-preview/${drawer ? "drawer" : "settings"}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
}
