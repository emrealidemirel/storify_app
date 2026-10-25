import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app/constants/release_config.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyLink extends StatelessWidget {
  const PrivacyLink({super.key});
  @override
  Widget build(BuildContext context) => TextButton(
    onPressed:
        () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PrivacyPage()),
        ),
    child: Text('privacy_title'.tr()),
  );
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('Unavailable');
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('link_error'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('privacy_title'.tr())),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'privacy_intro'.tr(),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 20),
        for (final key in [
          'privacy_account',
          'privacy_ai',
          'privacy_local',
          'privacy_reports',
          'privacy_delete',
        ]) ...[
          Text(key.tr(), style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 20),
        ],
        if (ReleaseConfig.publisher.isNotEmpty) Text(ReleaseConfig.publisher),
        if (ReleaseConfig.supportEmail.isNotEmpty)
          TextButton(
            onPressed:
                () => _open(
                  context,
                  Uri(scheme: 'mailto', path: ReleaseConfig.supportEmail),
                ),
            child: Text(ReleaseConfig.supportEmail),
          ),
        if (Uri.tryParse(ReleaseConfig.privacyUrl)?.scheme == 'https')
          TextButton(
            onPressed:
                () => _open(context, Uri.parse(ReleaseConfig.privacyUrl)),
            child: Text('privacy_full'.tr()),
          ),
        if (Uri.tryParse(ReleaseConfig.deletionUrl)?.scheme == 'https')
          TextButton(
            onPressed:
                () => _open(context, Uri.parse(ReleaseConfig.deletionUrl)),
            child: Text('deletion_web'.tr()),
          ),
      ],
    ),
  );
}
