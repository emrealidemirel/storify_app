import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_story_app/pages/theme_selection_page.dart';
import 'package:flutter_story_app/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    await (FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    for (final family in ['Lora', 'NunitoSans', 'Cinzel']) {
      await (FontLoader(family)
        ..addFont(rootBundle.load('assets/fonts/$family.ttf'))).load();
    }
  });

  Future<void> mount(
    WidgetTester tester,
    Size size,
    double scale,
    bool dark,
    void Function(String, String) onDone, {
    Locale locale = const Locale('tr', 'TR'),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 59, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
        startLocale: locale,
        saveLocale: false,
        path: 'assets/langs',
        assetLoader: const _Translations(),
        child: Builder(
          builder:
              (context) => MaterialApp(
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
                theme:
                    dark
                        ? AppTheme.darkTheme(context)
                        : AppTheme.lightTheme(context),
                builder:
                    (context, child) => MediaQuery(
                      data: MediaQuery.of(
                        context,
                      ).copyWith(textScaler: TextScaler.linear(scale)),
                      child: child!,
                    ),
                home: RepaintBoundary(
                  key: const ValueKey('preview'),
                  child: ThemeSelectionPage(onSelectionDone: onDone),
                ),
              ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 568),
    const Size(430, 932),
    const Size(768, 1024),
    const Size(932, 430),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final dark in [false, true]) {
        testWidgets(
          'selection fits $size scale=$scale dark=$dark and actions remain reachable',
          (tester) async {
            await mount(tester, size, scale, dark, (_, _) {});
            expect(tester.takeException(), isNull);
            expect(
              tester.getTopLeft(find.text('STORIFY')).dy,
              greaterThanOrEqualTo(59),
            );
            await tester.scrollUntilVisible(
              find.text('Beni şaşırt'),
              350,
              scrollable: find.byType(Scrollable).first,
            );
            expect(tester.takeException(), isNull);
            expect(find.text('Beni şaşırt').hitTestable(), findsOneWidget);
          },
        );
      }
    }
  }

  testWidgets('selection requires both choices and submits stable keys', (
    tester,
  ) async {
    List<String>? selected;
    await mount(
      tester,
      const Size(430, 932),
      1,
      false,
      (theme, gender) => selected = [theme, gender],
    );
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Macera'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.scrollUntilVisible(
      find.text('Kadın'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Kadın'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Hikayeye Başla'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hikayeye Başla'));
    expect(selected, ['theme_adventure', 'gender_female']);
  });

  testWidgets('English surprise action returns valid selections', (
    tester,
  ) async {
    List<String>? selected;
    await mount(
      tester,
      const Size(320, 568),
      2,
      true,
      (theme, gender) => selected = [theme, gender],
      locale: const Locale('en', 'US'),
    );
    await tester.scrollUntilVisible(
      find.text('Surprise me'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Surprise me'));
    expect(selected?.first, startsWith('theme_'));
    expect(selected?.last, isIn(['gender_male', 'gender_female']));
    expect(tester.takeException(), isNull);
  });

  testWidgets('render selection preview', (tester) async {
    await mount(tester, const Size(430, 1500), 1, false, (_, _) {});
    await tester.tap(find.text('Fantastik'));
    await tester.tap(find.text('Kadın'));
    await tester.pumpAndSettle();
    if (Platform.environment['CAPTURE_UI'] == '1') {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/ui-preview').createSync(recursive: true);
        File(
          'build/ui-preview/selection.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
  });
}
