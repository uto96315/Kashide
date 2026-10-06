import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/login/login_model.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/register/register_model.dart';
import 'package:str_gram_beta/resetPassword/reset_password_page.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, this.startWithRegister = false});

  final bool startWithRegister;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  late bool _register = widget.startWithRegister;

  @override
  Widget build(BuildContext context) {
    final login = ref.watch(loginProvider);
    final register = ref.watch(registerProvider);
    final loading = login.isLoading || register.isLoading;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF7F8),
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
                          layoutBuilder: (current, previous) {
                            return Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            );
                          },
                          transitionBuilder: (child, animation) {
                            final incoming = child.key == ValueKey(_register);
                            final begin = Offset(incoming ? (_register ? 0.06 : -0.06) : 0, 0);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(begin: begin, end: Offset.zero).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _register
                              ? _RegisterForm(key: const ValueKey(true), model: register, loading: loading)
                              : _LoginForm(key: const ValueKey(false), model: login, loading: loading),
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
              color: const Color(0xFFFFE4EC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  left: inset + (register ? thumbWidth : 0),
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
                    _label('ログイン', !register, () => onChanged(false)),
                    _label('新規登録', register, () => onChanged(true)),
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
  const _LoginForm({super.key, required this.model, required this.loading});

  final LoginModel model;
  final bool loading;

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
          child: _ActionChip(
            label: 'パスワードを忘れた場合',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordPage()));
            },
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
              await Navigator.pushNamed(context, '/home');
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
  const _RegisterForm({super.key, required this.model, required this.loading});

  final RegisterModel model;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldGroup(
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
        ),
        const SizedBox(height: 14),
        _ConsentChip(
          checked: model.consent,
          onToggle: () => model.setConsent(!model.consent),
          onOpenTerms: () {
            model.setConsent(true);
            launchUrl(Uri.parse('https://uto96315.github.io/Kashide_tos/'));
          },
        ),
        const SizedBox(height: 18),
        PrimaryButton(
          label: '登録する',
          loading: loading,
          onPressed: model.consent
              ? () async {
                  model.startLoading();
                  try {
                    await model.signIn();
                    await model.registerBlankData();
                    if (!context.mounted) return;
                    await Navigator.pushNamed(context, '/registerUserDetails');
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                  } finally {
                    model.endLoading();
                  }
                }
              : null,
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFE4EC),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: mainColor),
          ),
        ),
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
