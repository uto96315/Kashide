import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';

/// Firestore `feedback.category` に保存する値。
enum LabFeedbackCategory {
  inquiry('inquiry', 'お問い合わせ'),
  improvement('improvement', '改善要望'),
  collaboration('collaboration', 'コラボ依頼'),
  other('other', 'その他');

  const LabFeedbackCategory(this.storageKey, this.label);

  final String storageKey;
  final String label;

  String get hintText {
    switch (this) {
      case LabFeedbackCategory.inquiry:
        return '質問や不具合の内容';
      case LabFeedbackCategory.improvement:
        return '改善してほしい点';
      case LabFeedbackCategory.collaboration:
        return '会社名・連絡先・相談内容';
      case LabFeedbackCategory.other:
        return '内容';
    }
  }
}

class LabFeedbackService {
  static Future<void> submit({
    required LabFeedbackCategory category,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('not_signed_in');
    }
    final trimmed = message.trim();
    if (trimmed.length < 5) {
      throw ArgumentError('too_short');
    }

    String userName = '';
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      userName = snap.data()?['userName'] as String? ?? '';
    } catch (_) {}

    await FirebaseFirestore.instance.collection('feedback').add({
      'userId': user.uid,
      'userName': userName,
      'message': trimmed,
      'category': category.storageKey,
      'categoryLabel': category.label,
      'source': 'lab',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

void openLabFeedback(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const LabFeedbackPage()),
  );
}

class LabFeedbackPage extends StatefulWidget {
  const LabFeedbackPage({super.key});

  @override
  State<LabFeedbackPage> createState() => _LabFeedbackPageState();
}

class _LabFeedbackPageState extends State<LabFeedbackPage> {
  static const _bg = Color(0xFFF2F2F7);
  static const _ink = Color(0xFF0F1419);
  static const _muted = Color(0xFF8E8E93);

  final _controller = TextEditingController();
  var _category = LabFeedbackCategory.inquiry;
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await LabFeedbackService.submit(category: _category, message: _controller.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('送りました'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ArgumentError {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('5文字以上で書いてください')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('送信できませんでした')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final categories = LabFeedbackCategory.values;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          const ScreenTop(title: '運営に送る'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < categories.length; i++)
                        _CategoryRow(
                          label: _categoryLabel(categories[i]),
                          selected: _category == categories[i],
                          onTap: () => setState(() => _category = categories[i]),
                          showDivider: i < categories.length - 1,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  maxLines: 8,
                  maxLength: 800,
                  style: const TextStyle(fontSize: 16, height: 1.45, color: _ink),
                  decoration: InputDecoration(
                    hintText: _category.hintText,
                    hintStyle: const TextStyle(fontSize: 16, color: _muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ColoredBox(
            color: _bg,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12 + bottom),
                child: FilledButton(
                  onPressed: _sending ? null : _send,
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    disabledBackgroundColor: mainColor.withValues(alpha: 0.45),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _sending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('送信する'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _categoryLabel(LabFeedbackCategory c) {
    if (c == LabFeedbackCategory.collaboration) {
      return 'コラボ依頼（企業・インフルエンサー）';
    }
    return c.label;
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.showDivider,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: const Color(0xFF0F1419),
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(CupertinoIcons.checkmark, size: 20, color: mainColor)
                  else
                    const SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 16, color: Color(0xFFE5E5EA)),
      ],
    );
  }
}
