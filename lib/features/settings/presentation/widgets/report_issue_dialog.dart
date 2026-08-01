import 'package:aerofit/core/theme/app_theme.dart';
import 'package:aerofit/features/settings/providers/settings_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> showReportIssueDialog(
  BuildContext context,
  WidgetRef ref, {
  required String userEmail,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _ReportIssueDialog(
      userEmail: userEmail,
      onSubmit: (message) =>
          ref.read(settingsControllerProvider).submitIssueReport(message),
    ),
  );
}

class _ReportIssueDialog extends StatefulWidget {
  const _ReportIssueDialog({
    required this.userEmail,
    required this.onSubmit,
  });

  final String userEmail;
  final Future<void> Function(String message) onSubmit;

  @override
  State<_ReportIssueDialog> createState() => _ReportIssueDialogState();
}

class _ReportIssueDialogState extends State<_ReportIssueDialog> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await widget.onSubmit(_messageController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Issue reported successfully! We will get back to you via email.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send report: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF252B38)),
      ),
      title: const Text('Report an Issue'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: widget.userEmail,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Your Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Message / Issue Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.report_problem_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please describe the issue';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isSending ? null : _send,
          child: _isSending
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Report'),
        ),
      ],
    );
  }
}
