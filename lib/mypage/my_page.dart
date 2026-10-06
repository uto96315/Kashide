import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/liked/liked_posts_page.dart';
import 'package:str_gram_beta/playlist/playlist_page.dart';
import 'package:str_gram_beta/providers.dart';
import '../editPost/edit_post_page.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(myPageProvider);
    final hasAvatar = model.userImageURL != null && model.userImageURL != '' && model.userImageURL != 'null';
    return Scaffold(
      key: model.sidebarKey,
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    if (Navigator.of(context).canPop()) const AppBackButton() else const SizedBox(width: 16),
                    const Spacer(),
                    IconButton(
                      onPressed: () => model.sidebarKey.currentState?.openEndDrawer(),
                      icon: const Icon(Icons.menu, color: Color(0xFF1C1C1E)),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: const Color(0xFFE5E5EA),
                      backgroundImage: hasAvatar ? NetworkImage(model.userImageURL!) : null,
                      child: hasAvatar ? null : const Icon(Icons.person, size: 44, color: Color(0xFF8E8E93)),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      model.userName ?? '読み込み中...',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    if ((model.userIntroduction ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        model.userIntroduction!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF3A3A3C)),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _ProfileStat(
                            label: '投稿',
                            value: model.postsReady ? '${model.userPostsList.length}' : '—',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LikedPostsPage()));
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE5E5EA)),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.favorite, color: Color(0xFF1C1C1E), size: 22),
                                    SizedBox(height: 4),
                                    Text('いいねした', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (model.postsReady && model.userPostsList.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text('自分の投稿', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3C))),
                ),
              if (!model.postsReady)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator(color: mainColor)),
                )
              else if (model.userPostsList.isEmpty)
                const EmptyState(icon: Icons.edit_outlined, message: 'まだ投稿がありません')
              else
                Column(
                  children: [
                    for (final post in model.userPostsList)
                      LyricPostCard(
                        post: post,
                        showAuthor: false,
                        menuItems: const [
                          PopupMenuItem(value: 'edit', child: Text('編集する')),
                          PopupMenuItem(value: 'delete', child: Text('削除する')),
                        ],
                        onMenu: (value) async {
                          if (value == 'delete') {
                            final shouldDelete = await showAppConfirm(
                              context,
                              title: '投稿を削除',
                              message: 'この投稿を削除しますか？',
                              confirm: '削除する',
                              destructive: true,
                            );
                            if (shouldDelete) await model.deletePosts(post.id);
                          } else if (value == 'edit') {
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditPostPage(
                                  post.id,
                                  post.text,
                                  post.artist,
                                  post.singName,
                                  post.genres,
                                  post.explanation,
                                  post.youtubeLink,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Center(child: Text('Version ${Platform.isIOS ? model.iosVersion ?? '' : model.androidVersion ?? ''}')),
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('プロフィール編集', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditUserDetailsPage(
                      model.userName ?? '',
                      model.userAge ?? '',
                      model.userIntroduction ?? '',
                      model.userGender ?? '',
                      model.userFavorite!,
                      model.userImageURL ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('プレイリスト', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistPage()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('このアプリを評価する'),
              onTap: () => model.requestReview(),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('ログアウト', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                final ok = await showAppConfirm(
                  context,
                  title: 'ログアウト',
                  message: 'ログアウトしますか？',
                  confirm: 'ログアウト',
                );
                if (!ok || !context.mounted) return;
                await model.logOut();
                if (!context.mounted) return;
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E5EA)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ],
      ),
    );
  }
}
