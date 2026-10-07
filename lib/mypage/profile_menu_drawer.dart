import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/auth/saved_account.dart';
import 'package:str_gram_beta/common/network_image_utils.dart';
import 'package:str_gram_beta/auth/saved_accounts_store.dart';
import 'package:str_gram_beta/auth/user_session_refresh.dart';
import 'package:str_gram_beta/login/login_page.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/liked/liked_posts_page.dart';
import 'package:str_gram_beta/mypage/my_model.dart';
import 'package:str_gram_beta/playlist/playlist_page.dart';
import 'package:str_gram_beta/user/blocked_users_page.dart';

/// マイページ用・iOS 設定風の右ドロワー。
class ProfileMenuDrawer extends ConsumerStatefulWidget {
  const ProfileMenuDrawer({
    super.key,
    required this.model,
    required this.onLogOut,
  });

  final MyModel model;
  final Future<void> Function() onLogOut;

  static const _bg = Color(0xFFF2F2F7);
  static const _label = Color(0xFF3A3A3C);
  static const _secondary = Color(0xFF8E8E93);
  static const _separator = Color(0xFFE5E5EA);

  @override
  ConsumerState<ProfileMenuDrawer> createState() => _ProfileMenuDrawerState();
}

class _ProfileMenuDrawerState extends ConsumerState<ProfileMenuDrawer> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAccountList());
  }

  Future<void> _refreshAccountList() async {
    if (!mounted) return;
    await ref.read(savedAccountsProvider).ensureCurrentListed();
  }

  @override
  Widget build(BuildContext context) {
    final autoplay = ref.watch(cardAutoplaySettingsProvider);
    final savedAccounts = ref.watch(savedAccountsProvider);
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final version = Platform.isIOS ? widget.model.iosVersion : widget.model.androidVersion;
    final hasAvatar = isUsableNetworkImageUrl(widget.model.userImageURL);

    return Drawer(
      backgroundColor: ProfileMenuDrawer._bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.sizeOf(context).width * 0.86,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark, size: 22, color: ProfileMenuDrawer._label),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: ProfileMenuDrawer._separator,
                    backgroundImage:
                        hasAvatar ? NetworkImage(normalizeNetworkImageUrl(widget.model.userImageURL)!) : null,
                    child: hasAvatar
                        ? null
                        : const Icon(CupertinoIcons.person_fill, size: 28, color: ProfileMenuDrawer._secondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.model.userName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: ProfileMenuDrawer._label,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            if (savedAccounts.ready) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Text(
                  'アカウント',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ProfileMenuDrawer._secondary.withValues(alpha: 0.95),
                  ),
                ),
              ),
              _Section(
                children: [
                  if (savedAccounts.accounts.isEmpty)
                    _Tile(
                      icon: CupertinoIcons.person_fill,
                      title: widget.model.userName ?? '現在のアカウント',
                      showChevron: false,
                      onTap: () {},
                    )
                  else
                    for (var i = 0; i < savedAccounts.accounts.length; i++)
                      _AccountTile(
                        account: savedAccounts.accounts[i],
                        selected: savedAccounts.accounts[i].uid == currentUid,
                        showDivider: i < savedAccounts.accounts.length,
                        onTap: () => _switchAccount(context, ref, savedAccounts.accounts[i]),
                        onRemove: () => _removeAccount(context, ref, savedAccounts.accounts[i]),
                      ),
                  _Tile(
                    icon: CupertinoIcons.person_add,
                    title: 'アカウントを追加',
                    showDivider: false,
                    onTap: () => _openAddAccount(context, ref, savedAccounts.accounts.length),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
            _Section(
              children: [
                _Tile(
                  icon: CupertinoIcons.person_crop_circle,
                  title: 'プロフィール編集',
                  onTap: () => _closeAndPush(
                    context,
                    EditUserDetailsPage(
                      widget.model.userName ?? '',
                      widget.model.userAge ?? '',
                      widget.model.userIntroduction ?? '',
                      widget.model.userGender ?? '',
                      widget.model.userFavorite!,
                      widget.model.userImageURL ?? '',
                    ),
                  ),
                ),
                _Tile(
                  icon: CupertinoIcons.heart,
                  title: 'いいねした歌詞',
                  onTap: () => _closeAndPush(context, const LikedPostsPage()),
                ),
                _Tile(
                  icon: CupertinoIcons.music_note_list,
                  title: 'プレイリスト',
                  onTap: () => _closeAndPush(context, const PlaylistPage()),
                ),
                _Tile(
                  icon: CupertinoIcons.hand_raised,
                  title: 'ブロック中のユーザー',
                  onTap: () => _closeAndPush(context, const BlockedUsersPage()),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              children: [
                _SwitchTile(
                  icon: CupertinoIcons.play_circle,
                  title: 'カード表示で曲を自動再生',
                  subtitle: 'Apple Music プレビュー（約30秒）をアプリ内で再生します',
                  value: autoplay.enabled,
                  onChanged: (v) async {
                    await ref.read(cardAutoplaySettingsProvider).setEnabled(v);
                    if (!v) await ref.read(cardPreviewPlayerProvider).stop();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Section(
              children: [
                _Tile(
                  icon: CupertinoIcons.star,
                  title: Platform.isIOS ? 'App Store で評価する' : 'ストアで評価する',
                  onTap: () {
                    Navigator.pop(context);
                    widget.model.requestReview();
                  },
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _Section(
              children: [
                _Tile(
                  icon: CupertinoIcons.square_arrow_right,
                  title: 'ログアウト',
                  titleColor: const Color(0xFFFF3B30),
                  iconColor: const Color(0xFFFF3B30),
                  showChevron: false,
                  showDivider: false,
                  onTap: () async {
                    Navigator.pop(context);
                    final ok = await showAppConfirm(
                      context,
                      title: 'ログアウト',
                      message: 'ログアウトしますか？',
                      confirm: 'ログアウト',
                    );
                    if (!ok || !context.mounted) return;
                    await widget.onLogOut();
                  },
                ),
              ],
            ),
            if ((version ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'バージョン $version',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: ProfileMenuDrawer._secondary),
              ),
            ],
            const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _closeAndPush(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _switchAccount(BuildContext context, WidgetRef ref, SavedAccount account) async {
    if (account.uid == FirebaseAuth.instance.currentUser?.uid) return;
    if (!account.canQuickSwitch) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginPage(initialEmail: account.email, addingAccount: true),
        ),
      );
      return;
    }
    Navigator.pop(context);
    try {
      await ref.read(accountSwitchServiceProvider).switchToAccount(account);
      refreshAfterAccountChange(ref);
      await ref.read(savedAccountsProvider).reload();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('切り替えに失敗しました。パスワードを変更した場合は再度ログインしてください。')),
      );
    }
  }

  void _openAddAccount(BuildContext context, WidgetRef ref, int count) {
    if (count >= maxSavedAccounts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('アカウントは最大$maxSavedAccounts件まで保存できます')),
      );
      return;
    }
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage(addingAccount: true)),
    );
  }

  Future<void> _removeAccount(BuildContext context, WidgetRef ref, SavedAccount account) async {
    final ok = await showAppConfirm(
      context,
      title: '端末から削除',
      message: '${account.label} をこの端末の一覧から削除します。Firebase のアカウント自体は削除されません。',
      confirm: '削除',
    );
    if (!ok || !context.mounted) return;

    final isCurrent = account.uid == FirebaseAuth.instance.currentUser?.uid;
    await ref.read(savedAccountsProvider).removeFromDevice(account.uid);
    if (isCurrent) {
      await FirebaseAuth.instance.signOut();
      refreshAfterAccountChange(ref);
      if (!context.mounted) return;
      Navigator.popUntil(context, ModalRoute.withName('/'));
    }
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.selected,
    required this.onTap,
    required this.onRemove,
    this.showDivider = true,
  });

  final SavedAccount account;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = normalizeNetworkImageUrl(account.iconUrl);
    final hasAvatar = avatarUrl != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onRemove,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: ProfileMenuDrawer._separator,
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: hasAvatar
                        ? null
                        : const Icon(CupertinoIcons.person_fill, size: 16, color: ProfileMenuDrawer._secondary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: ProfileMenuDrawer._label,
                          ),
                        ),
                        if (account.displayName != null && account.displayName!.isNotEmpty)
                          Text(
                            account.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: ProfileMenuDrawer._secondary),
                          ),
                      ],
                    ),
                  ),
                  if (selected)
                    const Icon(CupertinoIcons.checkmark_circle_fill, size: 22, color: Color(0xFFFF749E)),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 52, color: ProfileMenuDrawer._separator),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 22, color: ProfileMenuDrawer._secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: ProfileMenuDrawer._label),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, height: 1.35, color: ProfileMenuDrawer._secondary),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: const Color(0xFFFF749E),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor = ProfileMenuDrawer._label,
    this.iconColor = ProfileMenuDrawer._secondary,
    this.showChevron = true,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;
  final bool showChevron;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: showDivider
                ? null
                : const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: titleColor),
                    ),
                  ),
                  if (showChevron)
                    const Icon(CupertinoIcons.chevron_forward, size: 18, color: Color(0xFFC7C7CC)),
                ],
              ),
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 0.5, indent: 52, color: ProfileMenuDrawer._separator),
      ],
    );
  }
}
