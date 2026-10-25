import 'package:flutter_story_app/widgets/brand_wordmark.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart';

class ThemeSelectionPage extends StatefulWidget {
  final Function(String themeKey, String genderKey) onSelectionDone;
  const ThemeSelectionPage({super.key, required this.onSelectionDone});
  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  static const themes = <String, IconData>{
    'theme_adventure': Icons.explore_outlined,
    'theme_fantasy': Icons.auto_awesome_outlined,
    'theme_mystery': Icons.key_outlined,
    'theme_scifi': Icons.rocket_launch_outlined,
    'theme_horror': Icons.nightlight_outlined,
    'theme_romantic': Icons.favorite_border,
    'theme_historical': Icons.account_balance_outlined,
    'theme_comedy': Icons.theater_comedy_outlined,
  };
  String selectedTheme = '';
  String selectedGender = '';
  bool get complete => selectedTheme.isNotEmpty && selectedGender.isNotEmpty;

  void _surprise() {
    final random = Random();
    widget.onSelectionDone(
      themes.keys.elementAt(random.nextInt(themes.length)),
      random.nextBool() ? 'gender_male' : 'gender_female',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      showDrawer: false,
      titleWidget: const BrandWordmark(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'selection_eyebrow'.tr(),
              style: TextStyle(
                color: theme.colorScheme.secondary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),
            Text('selection_title'.tr(), style: theme.textTheme.headlineLarge),
            const SizedBox(height: 10),
            Text('selection_subtitle'.tr(), style: theme.textTheme.bodyMedium),
            const SizedBox(height: 28),
            _section('01', 'select_theme'.tr(), selectedTheme.isNotEmpty),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final largeText =
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                final columns =
                    constraints.maxWidth >= 700
                        ? 4
                        : constraints.maxWidth < 310 || largeText
                        ? 1
                        : 2;
                final entries = themes.entries.toList();
                return Column(
                  children: [
                    for (var row = 0; row < entries.length; row += columns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (var col = 0; col < columns; col++) ...[
                                if (col > 0) const SizedBox(width: 12),
                                Expanded(
                                  child: _SelectionCard(
                                    label: entries[row + col].key.tr(),
                                    description:
                                        '${entries[row + col].key}_description'
                                            .tr(),
                                    icon: entries[row + col].value,
                                    selected:
                                        selectedTheme == entries[row + col].key,
                                    onTap:
                                        () => setState(
                                          () =>
                                              selectedTheme =
                                                  entries[row + col].key,
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 28),
            _section('02', 'select_gender'.tr(), selectedGender.isNotEmpty),
            const SizedBox(height: 8),
            Text(
              'character_description'.tr(),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final single =
                    constraints.maxWidth < 310 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children:
                      ['gender_female', 'gender_male']
                          .map(
                            (gender) => SizedBox(
                              width:
                                  single
                                      ? constraints.maxWidth
                                      : (constraints.maxWidth - 12) / 2,
                              child: _SelectionCard(
                                label: gender.tr(),
                                icon:
                                    gender == 'gender_female'
                                        ? Icons.female
                                        : Icons.male,
                                selected: selectedGender == gender,
                                onTap:
                                    () =>
                                        setState(() => selectedGender = gender),
                              ),
                            ),
                          )
                          .toList(),
                );
              },
            ),
            const SizedBox(height: 28),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                complete
                    ? '${selectedTheme.tr()} · ${selectedGender.tr()}'
                    : 'selection_hint'.tr(),
                key: ValueKey('$selectedTheme/$selectedGender'),
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    complete
                        ? () => widget.onSelectionDone(
                          selectedTheme,
                          selectedGender,
                        )
                        : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text('start_story_button'.tr()),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _surprise,
                icon: const Icon(Icons.shuffle, size: 18),
                label: Text('surprise_me'.tr()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String number, String title, bool done) => Row(
    children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            done
                ? Icon(
                  Icons.check,
                  size: 17,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                )
                : Text(
                  number,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    ],
  );
}

class _SelectionCard extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _SelectionCard({
    required this.label,
    this.description,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color:
              selected ? scheme.secondaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected
                    ? scheme.secondary
                    : scheme.outlineVariant.withValues(alpha: .6),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 26, color: scheme.secondary),
                      const Spacer(),
                      Icon(
                        selected ? Icons.check_circle : Icons.circle_outlined,
                        size: 20,
                        color:
                            selected ? scheme.secondary : scheme.outlineVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
