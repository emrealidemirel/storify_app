import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_story_app/widgets/theme_button.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_story_app/widgets/app_scaffold.dart'; 

class ThemeSelectionPage extends StatefulWidget {
  final Function(String themeKey, String genderKey) onSelectionDone;

  const ThemeSelectionPage({super.key, required this.onSelectionDone});

  @override
  State<ThemeSelectionPage> createState() => _ThemeSelectionPageState();
}

class _ThemeSelectionPageState extends State<ThemeSelectionPage> {
  final List<String> themeKeys = [
    'theme_horror',
    'theme_adventure',
    'theme_romantic',
    'theme_fantasy',
    'theme_scifi',
    'theme_historical',
    'theme_mystery',
    'theme_comedy',
  ];

  final List<String> genderKeys = ['gender_male', 'gender_female'];

  String selectedTheme = '';
  String selectedGender = '';

  bool get isSelectionComplete =>
      selectedTheme.isNotEmpty && selectedGender.isNotEmpty;

  void _skipSelection() {
    final random = Random();
    final randTheme = themeKeys[random.nextInt(themeKeys.length)];
    final randGender = genderKeys[random.nextInt(genderKeys.length)];
    widget.onSelectionDone(randTheme, randGender);
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = Colors.deepPurple.shade400;

    return AppScaffold( 
      appBar: AppBar(
        title: Text('app_title'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'select_theme'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 3.h),
            ThemeButton(
              selectedValue: selectedTheme.isNotEmpty ? selectedTheme.tr() : '',
              options: themeKeys.map((k) => k.tr()).toList(),
              onChanged: (value) {
                final key = themeKeys.firstWhere((k) => k.tr() == value);
                setState(() {
                  selectedTheme = key;
                });
              },
            ),
            SizedBox(height: 5.h),
            Text(
              'select_gender'.tr(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            SizedBox(height: 3.h),
            ThemeButton(
              selectedValue:
                  selectedGender.isNotEmpty ? selectedGender.tr() : '',
              options: genderKeys.map((k) => k.tr()).toList(),
              onChanged: (value) {
                final key = genderKeys.firstWhere((k) => k.tr() == value);
                setState(() {
                  selectedGender = key;
                });
              },
            ),
            const Spacer(),
            SizedBox(
              width: 60.w,
              height: 6.h,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelectionComplete
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).disabledColor,
                ),
                onPressed:
                    isSelectionComplete
                        ? () => widget.onSelectionDone(
                          selectedTheme,
                          selectedGender,
                        )
                        : null,
                child: Text(
                  'start_button'.tr(),
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: Colors.white),
                ),
              ),
            ),

            SizedBox(height: 2.h),
            SizedBox(
              width: 60.w,
              height: 6.h,
              child: TextButton(
                onPressed: _skipSelection,
                child: Text(
                  'skip_button'.tr(),
                  style: Theme.of(context).textTheme.labelMedium!.copyWith(
                    color: secondaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}