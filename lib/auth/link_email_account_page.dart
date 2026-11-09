import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/auth/link_anonymous_account_service.dart';
import 'package:str_gram_beta/auth/user_session_refresh.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';

class LinkEmailAccountPage extends ConsumerStatefulWidget {
  const LinkEmailAccountPage({super.key});

  @override
  ConsumerState<LinkEmailAccountPage> createState() => _LinkEmailAccountPageState();
}

class _LinkEmailAccountPageState extends ConsumerState<LinkEmailAccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _service = LinkAnonymousAccountService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスとパスワードを入力してください')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.linkEmailAndPassword(email: email, password: password);
      await ref.read(savedAccountsProvider).syncAfterAuth(email: email, password: password);
      refreshAfterAccountChange(ref, homeTabIndex: 3);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('メールアドレスを登録しました')),
      );
    } on LinkAnonymousAccountException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(
                height: 44,
                child: Align(alignment: Alignment.centerLeft, child: AppBackButton()),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'メールアドレスを登録',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '登録すると端末を替えても同じアカウントで利用できます。投稿やいいねも引き続き使えます。',
                        style: TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF8E8E93)),
                      ),
                      const SizedBox(height: 24),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                hintText: 'メールアドレス',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                            ),
                            const Divider(height: 0.5, thickness: 0.5, indent: 16, color: Color(0xFFE5E5EA)),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                hintText: 'パスワード（6文字以上）',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                suffixIcon: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(44, 44),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
                                    size: 18,
                                    color: const Color(0xFF8E8E93),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: '登録する',
                        loading: _loading,
                        onPressed: _loading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
