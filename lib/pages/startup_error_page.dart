import 'package:flutter/material.dart';
import 'package:flutter_story_app/theme/app_theme.dart';

class StartupErrorApp extends StatefulWidget {
  final Future<void> Function() retry;
  const StartupErrorApp({super.key, required this.retry});
  @override
  State<StartupErrorApp> createState() => _StartupErrorAppState();
}

class _StartupErrorAppState extends State<StartupErrorApp> {
  bool _retrying = false;
  @override
  Widget build(BuildContext context) {
    final tr =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode == 'tr';
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(context),
      darkTheme: AppTheme.darkTheme(context),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined, size: 48),
                const SizedBox(height: 20),
                Text(
                  tr
                      ? 'Storify başlatılamadı. Bağlantını kontrol edip tekrar deneyebilirsin.'
                      : 'Storify could not start. Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                if (_retrying)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      setState(() => _retrying = true);
                      await widget.retry();
                      if (mounted) setState(() => _retrying = false);
                    },
                    child: Text(tr ? 'Tekrar dene' : 'Try again'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
