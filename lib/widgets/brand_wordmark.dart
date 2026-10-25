import 'package:flutter/material.dart';
import 'package:flutter_story_app/theme/app_theme.dart';

/// One consistent, locally bundled wordmark across navigation and auth screens.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(
      'STORIFY',
      maxLines: 1,
      style: TextStyle(
        fontFamily: 'Cinzel',
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        height: 1.2,
        color:
            Theme.of(context).brightness == Brightness.dark
                ? AppTheme.gold
                : const Color(0xFF795526),
      ),
    ),
  );
}
