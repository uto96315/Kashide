import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/auth/user_session_refresh.dart';
import 'package:str_gram_beta/common/network_image_utils.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/providers.dart';

class TopPage extends ConsumerWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(topProvider);
    final saved = ref.watch(savedAccountsProvider);

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFFF3F6)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              children: [
                const Spacer(),
                SizedBox(
                  width: MediaQuery.sizeOf(context).width * 0.52,
                  child: Image.asset('images/splash_new.png', fit: BoxFit.contain),
                ),
                const SizedBox(height: 20),
                const Text(
                  '気に入った歌詞から、曲に出会う',
                  style: TextStyle(fontSize: 15, color: Color(0xFF8E8E93)),
                ),
                if (saved.ready && saved.accounts.isNotEmpty) ...[
                  const SizedBox(height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '保存済みアカウント',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...saved.accounts.map(
                    (account) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SavedAccountChip(
                        label: account.label,
                        iconUrl: account.iconUrl,
                        onTap: () => _signInSaved(context, ref, account.uid),
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                PrimaryButton(
                  label: 'はじめる',
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signInSaved(BuildContext context, WidgetRef ref, String uid) async {
    final account = ref.read(savedAccountsProvider).accounts.where((a) => a.uid == uid).firstOrNull;
    if (account == null) return;
    try {
      await ref.read(accountSwitchServiceProvider).switchToAccount(account);
      await ref.read(savedAccountsProvider).reload();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインに失敗しました。通常のログインからやり直してください。')),
      );
    }
  }
}

class _SavedAccountChip extends StatelessWidget {
  const _SavedAccountChip({required this.label, required this.iconUrl, required this.onTap});

  final String label;
  final String? iconUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = normalizeNetworkImageUrl(iconUrl);
    final hasAvatar = avatarUrl != null;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE7E9EA),
                backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                child: hasAvatar
                    ? null
                    : const Icon(CupertinoIcons.person_fill, size: 18, color: Color(0xFF536471)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F1419)),
                ),
              ),
              const Icon(CupertinoIcons.chevron_forward, size: 18, color: Color(0xFFC7C7CC)),
            ],
          ),
        ),
      ),
    );
  }
}
