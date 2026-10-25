import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  static const espresso = Color(0xFF302019);
  static const gold = Color(0xFFD6AF62);

  static ThemeData lightTheme(BuildContext context) => _theme(Brightness.light);
  static ThemeData darkTheme(BuildContext context) => _theme(Brightness.dark);

  static ThemeData _theme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF93703D),
      brightness: brightness,
      primary: dark ? gold : espresso,
      onPrimary: dark ? espresso : const Color(0xFFFFF8EB),
      secondary: dark ? gold : const Color(0xFF785A28),
      surface: dark ? const Color(0xFF211B17) : const Color(0xFFFCF8F1),
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = base.textTheme.apply(fontFamily: 'NunitoSans');
    return base.copyWith(
      primaryColor: espresso,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        headlineLarge: TextStyle(
          fontFamily: 'Lora',
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Lora',
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'Lora',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
        bodyMedium: text.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
          color: scheme.onSurfaceVariant,
        ),
        labelLarge: text.labelLarge?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        toolbarHeight: 72,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle:
            dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: 'Lora',
          fontSize: 23,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(48, 56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        constraints: const BoxConstraints(minHeight: 60),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
        errorMaxLines: 3,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.secondary, width: 1.5),
        ),
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: .5),
      ),
    );
  }
}
