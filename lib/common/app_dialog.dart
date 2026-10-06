import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

Future<bool> showAppConfirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'はい',
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => _AppDialog(
      title: title,
      message: message,
      actions: [
        _DialogAction(label: 'キャンセル', onPressed: () => Navigator.pop(context, false)),
        _DialogAction(
          label: confirm,
          emphasized: true,
          destructive: destructive,
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<void> showAppMessage(BuildContext context, String message) {
  return showDialog<void>(
    context: context,
    builder: (context) => _AppDialog(
      message: message,
      actions: [
        _DialogAction(label: 'OK', emphasized: true, onPressed: () => Navigator.pop(context)),
      ],
    ),
  );
}

class _AppDialog extends StatelessWidget {
  const _AppDialog({required this.message, required this.actions, this.title});

  final String? title;
  final String message;
  final List<_DialogAction> actions;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(title!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
            ],
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF3A3A3C))),
            const SizedBox(height: 8),
            Row(children: [for (final action in actions) Expanded(child: action)]),
          ],
        ),
      ),
    );
  }
}

class _DialogAction extends StatelessWidget {
  const _DialogAction({
    required this.label,
    required this.onPressed,
    this.emphasized = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool emphasized;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? const Color(0xFFD70015) : (emphasized ? mainColor : const Color(0xFF8E8E93));
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: TextStyle(color: color, fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500)),
    );
  }
}
