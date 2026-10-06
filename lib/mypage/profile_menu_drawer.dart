import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/liked/liked_posts_page.dart';
import 'package:str_gram_beta/mypage/my_model.dart';
import 'package:str_gram_beta/playlist/playlist_page.dart';

/// マイページ用・iOS 設定風の右ドロワー。
class ProfileMenuDrawer extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final version = Platform.isIOS ? model.iosVersion : model.androidVersion;
    final hasAvatar =
        model.userImageURL != null && model.userImageURL!.isNotEmpty && model.userImageURL != 'null';

    return Drawer(
      backgroundColor: _bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.sizeOf(context).width * 0.86,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(CupertinoIcons.xmark, size: 22, color: _label),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _separator,
                    backgroundImage: hasAvatar ? NetworkImage(model.userImageURL!) : null,
                    child: hasAvatar
                        ? null
                        : const Icon(CupertinoIcons.person_fill, size: 28, color: _secondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      model.userName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _label,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _Section(
              children: [
                _Tile(
                  icon: CupertinoIcons.person_crop_circle,
                  title: 'プロフィール編集',
                  onTap: () => _closeAndPush(
                    context,
                    EditUserDetailsPage(
                      model.userName ?? '',
                      model.userAge ?? '',
                      model.userIntroduction ?? '',
                      model.userGender ?? '',
                      model.userFavorite!,
                      model.userImageURL ?? '',
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
                  showDivider: false,
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
                    model.requestReview();
                  },
                  showDivider: false,
                ),
              ],
            ),
            const Spacer(),
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
                    await onLogOut();
                  },
                ),
              ],
            ),
            if ((version ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'バージョン $version',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: _secondary),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _closeAndPush(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
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
