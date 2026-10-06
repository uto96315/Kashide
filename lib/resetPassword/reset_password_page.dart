import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';

class ResetPasswordPage extends ConsumerWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(resetPasswordProvider);
    final email = model.resetEmail?.trim() ?? '';
    final canSend = email.contains('@') && email.contains('.');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F8),
        body: Column(
          children: [
            const ScreenTop(),
            Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '登録しているメールアドレスに、再設定用のメールを送ります。',
                        style: TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF1C1C1E)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '届かないときは迷惑メールも確認してください。',
                        style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: model.resetEmailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: model.setEmail,
                        style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
                        cursorColor: mainColor,
                        decoration: const InputDecoration(
                          hintText: 'メールアドレス',
                          hintStyle: TextStyle(color: Color(0xFFC7C7CC), fontSize: 16),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if ((model.alertMessage ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          model.alertMessage!,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFD70015)),
                        ),
                      ],
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: '送信する',
                        onPressed: canSend
                            ? () async {
                                final ok = await showAppConfirm(
                                  context,
                                  title: 'パスワード再設定',
                                  message: '再設定用のメールを送信しますか？',
                                  confirm: '送信する',
                                );
                                if (!ok || !context.mounted) return;
                                await model.resetPassword(email);
                                if (!context.mounted) return;
                                Navigator.popUntil(context, (route) => route.isFirst);
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }
}
