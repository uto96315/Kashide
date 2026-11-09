import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/login/login_model.dart';
import 'package:str_gram_beta/auth/user_session_refresh.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/register/register_model.dart';
import 'package:str_gram_beta/resetPassword/reset_password_page.dart';
import 'package:url_launcher/url_launcher.dart';

String _authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'operation-not-allowed':
        return '匿名ログインが有効になっていません。しばらくしてからお試しください。';
      case 'network-request-failed':
        return 'ネットワークに接続できませんでした。';
      default:
        break;
    }
  }
  return error.toString();
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    super.key,
    this.startWithRegister = true,
    this.addingAccount = false,
    this.reauthForQuickSwitch = false,
    this.initialEmail,
  });

  /// ログイン済みの端末に別アカウントを追加するとき。
  final bool startWithRegister;
  final bool addingAccount;
  /// 保存済みアカウントのパスワード再入力（ワンタップ切替用）。
  final bool reauthForQuickSwitch;
  final String? initialEmail;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late bool _register;

  @override
  void initState() {
    super.initState();
    final email = widget.initialEmail?.trim();
    _register = widget.reauthForQuickSwitch
        ? false
        : (email != null && email.isNotEmpty)
            ? false
            : widget.startWithRegister;
    if (email != null && email.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final login = ref.read(loginProvider);
        login.loginEmailController.text = email;
        login.setEmail(email);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginProvider);
    final register = ref.watch(registerProvider);
    final loading = login.isLoading || register.isLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF9F9F9),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AppBackButton(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SlidingToggle(
                        register: _register,
                        onChanged: (value) => setState(() => _register = value),
                      ),
                      const SizedBox(height: 22),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 240),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final incoming = child.key == ValueKey(_register);
                            final begin = Offset(incoming ? (_register ? -0.06 : 0.06) : 0, 0);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _register
                              ? _RegisterForm(
                                  key: const ValueKey('register_form'),
                                  model: register,
                                  loading: loading,
                                  showGuestEntry: !widget.reauthForQuickSwitch,
                                  onRegistered: () => _onRegistered(context, register),
                                  onPrepareGuestSignIn: _prepareGuestSignIn,
                                  onGuestStart: () => _onGuestStart(context, register),
                                )
                              : _LoginForm(
                                  key: const ValueKey(false),
                                  model: login,
                                  loading: loading,
                                  onLoggedIn: () => _onLoggedIn(context, login),
                                ),
                        ),
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

  Future<void> _onLoggedIn(BuildContext context, LoginModel model) async {
    await ref.read(savedAccountsProvider).syncAfterAuth(
          email: model.loginEmailController.text.trim(),
          password: model.loginPasswordController.text,
        );
    if (!context.mounted) return;
    refreshAfterAccountChange(
      ref,
      homeTabIndex: (widget.addingAccount || widget.reauthForQuickSwitch) ? 3 : 0,
    );
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      await Navigator.pushNamed(context, '/home');
    }
  }

  Future<void> _onRegistered(BuildContext context, RegisterModel model) async {
    await ref.read(savedAccountsProvider).syncAfterAuth(
          email: model.registerEmailController.text.trim(),
          password: model.registerPasswordController.text,
        );
    await model.registerBlankData();
    if (!context.mounted) return;
    await Navigator.pushNamed(
      context,
      '/registerUserDetails',
      arguments: widget.addingAccount,
    );
  }

  Future<void> _prepareGuestSignIn() async {
    if (!widget.addingAccount) return;
    await ref.read(savedAccountsProvider).persistAnonymous();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> _onGuestStart(BuildContext context, RegisterModel model) async {
    await model.registerBlankData(anonymous: true);
    await ref.read(savedAccountsProvider).persistAnonymous();
    if (!context.mounted) return;
    refreshAfterAccountChange(
      ref,
      homeTabIndex: widget.addingAccount ? 3 : 0,
    );
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      await Navigator.pushNamed(context, '/home');
    }
  }

}

class _SlidingToggle extends StatelessWidget {
  const _SlidingToggle({required this.register, required this.onChanged});

  final bool register;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const inset = 4.0;
        final thumbWidth = (constraints.maxWidth - inset * 2) / 2;
        return SizedBox(
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: inset + (register ? 0 : thumbWidth),
                  top: inset,
                  width: thumbWidth,
                  height: 48 - inset * 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: Color(0x33FF749E), blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    _label('新規登録', register, () => onChanged(true)),
                    _label('ログイン', !register, () => onChanged(false)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? mainColor : const Color(0xFF1C1C1E),
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    super.key,
    required this.model,
    required this.loading,
    required this.onLoggedIn,
  });

  final LoginModel model;
  final bool loading;
  final Future<void> Function() onLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldGroup(
          children: [
            _LineField(
              controller: model.loginEmailController,
              hint: 'メールアドレス',
              keyboardType: TextInputType.emailAddress,
              onChanged: model.setEmail,
            ),
            _LineField(
              controller: model.loginPasswordController,
              hint: 'パスワード',
              obscure: model.passObscure,
              onChanged: model.setPassword,
              trailing: _EyeButton(obscure: model.passObscure, onPressed: model.changeObscure),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordPage()));
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF8E8E93),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            child: const Text('パスワードを忘れた場合'),
          ),
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'ログイン',
          loading: loading,
          onPressed: () async {
            model.startLoading();
            try {
              await model.login();
              if (!context.mounted) return;
              await onLoggedIn();
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
            } finally {
              model.endLoading();
            }
          },
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    super.key,
    required this.model,
    required this.loading,
    required this.showGuestEntry,
    required this.onRegistered,
    required this.onPrepareGuestSignIn,
    required this.onGuestStart,
  });

  final RegisterModel model;
  final bool loading;
  final bool showGuestEntry;
  final Future<void> Function() onRegistered;
  final Future<void> Function() onPrepareGuestSignIn;
  final Future<void> Function() onGuestStart;

  Future<void> _runGuestStart(BuildContext context) async {
    if (!model.consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約への同意が必要です')),
      );
      return;
    }
    model.startLoading();
    try {
      await onPrepareGuestSignIn();
      await model.signInAnonymously();
      if (!context.mounted) return;
      await onGuestStart();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(e))),
      );
    } finally {
      model.endLoading();
    }
  }

  Future<void> _runEmailRegister(BuildContext context) async {
    if (!model.consent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約への同意が必要です')),
      );
      return;
    }
    model.startLoading();
    try {
      await model.signIn();
      if (!context.mounted) return;
      await onRegistered();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authErrorMessage(e))),
      );
    } finally {
      model.endLoading();
    }
  }

  Widget _consentChip() {
    return _ConsentChip(
      checked: model.consent,
      onToggle: () => model.setConsent(!model.consent),
      onOpenTerms: () {
        model.setConsent(true);
        launchUrl(Uri.parse('https://uto96315.github.io/Kashide_tos/'));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailFields = _FieldGroup(
      children: [
        _LineField(
          controller: model.registerEmailController,
          hint: 'メールアドレス',
          keyboardType: TextInputType.emailAddress,
          onChanged: model.setEmail,
        ),
        _LineField(
          controller: model.registerPasswordController,
          hint: 'パスワード',
          obscure: model.passObscure,
          onChanged: model.setPassword,
          trailing: _EyeButton(obscure: model.passObscure, onPressed: model.changeObscure),
        ),
      ],
    );

    if (!showGuestEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          emailFields,
          const SizedBox(height: 20),
          _consentChip(),
          const SizedBox(height: 12),
          PrimaryButton(
            label: '登録する',
            loading: loading,
            onPressed: !loading ? () => _runEmailRegister(context) : null,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'アカウントなしですぐ試せます',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
        ),
        const SizedBox(height: 24),
        _consentChip(),
        const SizedBox(height: 12),
        PrimaryButton(
          label: '登録せずに始めてみる',
          loading: loading,
          onPressed: !loading ? () => _runGuestStart(context) : null,
        ),
        const SizedBox(height: 22),
        const _MutedDivider(label: 'または'),
        const SizedBox(height: 18),
        emailFields,
        const SizedBox(height: 14),
        _EmailRegisterButton(
          loading: loading,
          onPressed: !loading ? () => _runEmailRegister(context) : null,
        ),
      ],
    );
  }
}

class _MutedDivider extends StatelessWidget {
  const _MutedDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF8E8E93)),
          ),
        ),
        const Expanded(child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E5EA))),
      ],
    );
  }
}

class _EmailRegisterButton extends StatelessWidget {
  const _EmailRegisterButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: mainColor,
          backgroundColor: Colors.white,
          disabledForegroundColor: const Color(0xFF6C6C70),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE5E5EA)),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: mainColor),
              )
            : const Text('メールアドレスで登録'),
      ),
    );
  }
}

class _ConsentChip extends StatelessWidget {
  const _ConsentChip({
    required this.checked,
    required this.onToggle,
    required this.onOpenTerms,
  });

  final bool checked;
  final VoidCallback onToggle;
  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: checked ? const Color(0xFFFFE4EC) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                checked ? Icons.check_circle : Icons.circle_outlined,
                color: checked ? mainColor : const Color(0xFFC7C7CC),
                size: 22,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '利用規約に同意する',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                ),
              ),
              GestureDetector(
                onTap: onOpenTerms,
                behavior: HitTestBehavior.opaque,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    '見る',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mainColor),
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

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 0.5, thickness: 0.5, indent: 16, color: Color(0xFFE5E5EA)));
      }
      rows.add(children[i]);
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: rows),
    );
  }
}

class _LineField extends StatelessWidget {
  const _LineField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.keyboardType,
    this.obscure = false,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
      cursorColor: mainColor,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFC7C7CC), fontSize: 16),
        filled: false,
        isDense: true,
        suffixIcon: trailing,
        suffixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }
}

class _EyeButton extends StatelessWidget {
  const _EyeButton({required this.obscure, required this.onPressed});

  final bool obscure;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: const Size(44, 44),
      onPressed: onPressed,
      child: Icon(
        obscure ? CupertinoIcons.eye_slash : CupertinoIcons.eye,
        size: 18,
        color: const Color(0xFF8E8E93),
      ),
    );
  }
}
