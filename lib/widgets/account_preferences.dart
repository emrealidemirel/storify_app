import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_story_app/blocs/theme/theme_cubit.dart';
import 'package:flutter_story_app/services/preferences_service.dart';
import 'package:flutter_story_app/widgets/account_widgets.dart';

class AccountPreferences extends StatelessWidget {
  const AccountPreferences({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeCubit>().state.themeMode == ThemeMode.dark;
    return Column(
      children: [
        AccountTile(
          icon: Icons.language_rounded,
          title: 'language'.tr(),
          subtitle:
              (context.locale.languageCode == 'tr' ? 'turkish' : 'english')
                  .tr(),
          onTap: () => _chooseLanguage(context),
        ),
        const Divider(height: 1, indent: 18, endIndent: 18),
        AccountTile(
          icon: dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          title: 'appearance'.tr(),
          subtitle: (dark ? 'dark_theme' : 'light_theme').tr(),
          onTap: () => context.read<ThemeCubit>().toggleTheme(),
          trailing: Semantics(
            label: 'dark_theme'.tr(),
            child: Switch(
              value: dark,
              onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseLanguage(BuildContext context) async {
    final selected = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder:
          (sheetContext) => SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'language'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'language_description'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  for (final locale in [
                    const Locale('tr', 'TR'),
                    const Locale('en', 'US'),
                  ])
                    AccountTile(
                      icon: Icons.translate,
                      title: locale.languageCode == 'tr' ? 'Türkçe' : 'English',
                      selected: context.locale == locale,
                      trailing: Icon(
                        context.locale == locale
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      onTap: () => Navigator.pop(sheetContext, locale),
                    ),
                ],
              ),
            ),
          ),
    );
    if (selected == null || !context.mounted) return;
    await context.setLocale(selected);
    await PreferencesService.saveLanguageCode(selected.languageCode);
  }
}
