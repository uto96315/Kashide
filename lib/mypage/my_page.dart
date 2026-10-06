import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/liked/liked_posts_page.dart';
import 'package:str_gram_beta/mypage/profile_menu_drawer.dart';
import 'package:str_gram_beta/providers.dart';
import '../editPost/edit_post_page.dart';

class MyPage extends ConsumerWidget {
  const MyPage({super.key});

  static const _bg = Color(0xFFF2F2F7);
  static const _primaryText = Color(0xFF0F1419);
  static const _secondaryText = Color(0xFF536471);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(myPageProvider);
    final hasAvatar =
        model.userImageURL != null && model.userImageURL != '' && model.userImageURL != 'null';
    final postCount = model.postsReady ? '${model.userPostsList.length}' : '—';
    final likedCount = model.likedCountReady ? '${model.likedPostsCount}' : '—';

    return Scaffold(
      key: model.sidebarKey,
      backgroundColor: _bg,
      endDrawer: ProfileMenuDrawer(
        model: model,
        onLogOut: () async {
          await model.logOut();
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        },
      ),
      body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ColoredBox(
                color: Colors.white,
                child: SafeArea(
                  bottom: false,
                  child: Column(
                  children: [
                    SizedBox(
                      height: 44,
                      child: Row(
                        children: [
                          if (Navigator.of(context).canPop())
                            const AppBackButton()
                          else
                            const SizedBox(width: 8),
                          const Spacer(),
                          IconButton(
                            onPressed: () => model.sidebarKey.currentState?.openEndDrawer(),
                            icon: const Icon(CupertinoIcons.bars, size: 24, color: _primaryText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFFE7E9EA),
                      backgroundImage: hasAvatar ? NetworkImage(model.userImageURL!) : null,
                      child: hasAvatar
                          ? null
                          : const Icon(CupertinoIcons.person_fill, size: 40, color: _secondaryText),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      model.userName ?? '読み込み中...',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _primaryText,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if ((model.userIntroduction ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          model.userIntroduction!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, height: 1.45, color: _secondaryText),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _ProfileMetric(value: postCount, label: '投稿'),
                        const SizedBox(width: 32),
                        _ProfileMetric(
                          value: likedCount,
                          label: 'いいね',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const LikedPostsPage()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFEFF3F4)),
                  ],
                  ),
                ),
              ),
            ),
            if (!model.postsReady)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator(color: mainColor)),
              )
            else if (model.userPostsList.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(icon: Icons.edit_outlined, message: 'まだ投稿がありません'),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = model.userPostsList[index];
                    return LyricPostCard(
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
                    );
                  },
                  childCount: model.userPostsList.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.value,
    required this.label,
    this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: MyPage._primaryText,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: MyPage._secondaryText),
        ),
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: content,
        ),
      ),
    );
  }
}
