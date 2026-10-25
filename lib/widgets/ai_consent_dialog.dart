import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app/pages/privacy_page.dart';
import 'package:flutter_story_app/services/preferences_service.dart';

Future<bool> ensureAIConsent(BuildContext context, String uid) async {
  if (await PreferencesService.hasAIConsent(uid)) return context.mounted;
  if (!context.mounted) return false;
  final accepted = await showDialog<bool>(
    context: context,
    builder:
        (context) => AlertDialog(
          title: Text('ai_consent_title'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [Text('ai_consent_body'.tr()), const PrivacyLink()],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('ai_consent_accept'.tr()),
            ),
          ],
        ),
  );
  if (accepted != true) return false;
  await PreferencesService.setAIConsent(uid, true);
  return context.mounted;
}
