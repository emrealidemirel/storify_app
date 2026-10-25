import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_story_app/services/firebase_storage_service.dart';

class StoryReportDialog extends StatefulWidget {
  final String userId;
  final List<String> passages;
  final List<String> choices;
  final FirebaseStorageService? storage;
  const StoryReportDialog({
    super.key,
    required this.userId,
    required this.passages,
    required this.choices,
    this.storage,
  });
  @override
  State<StoryReportDialog> createState() => _StoryReportDialogState();
}

class _StoryReportDialogState extends State<StoryReportDialog> {
  String _reason = 'unsafe';
  bool _sending = false;
  String? _error;
  Future<void> _send() async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await (widget.storage ?? FirebaseStorageService()).submitStoryReport(
        userId: widget.userId,
        passages: widget.passages,
        choices: widget.choices,
        reason: _reason,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'report_failed'.tr();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_sending,
    child: AlertDialog(
      title: Text('report_story'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('report_disclosure'.tr()),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              isExpanded: true,
              items:
                  ['unsafe', 'offensive', 'other']
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text('report_$reason'.tr()),
                        ),
                      )
                      .toList(),
              onChanged:
                  _sending ? null : (value) => setState(() => _reason = value!),
            ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: Text('cancel'.tr()),
        ),
        TextButton(
          onPressed: _sending ? null : _send,
          child: Text('report_send'.tr()),
        ),
      ],
    ),
  );
}
