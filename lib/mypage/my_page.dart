import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/liked/liked_posts_page.dart';
import 'package:str_gram_beta/playlist/playlist_page.dart';
import 'package:str_gram_beta/mypage/profile_menu_drawer.dart';
import 'package:str_gram_beta/auth/user_session_refresh.dart';
import 'package:str_gram_beta/providers.dart';
import '../editPost/edit_post_page.dart';

class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  static const _bg = Color(0xFFF2F2F7);
  static const _primaryText = Color(0xFF0F1419);
  static const _secondaryText = Color(0xFF536471);

  final _scrollController = ScrollController();
  final _postsSectionKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPosts() {
    final target = _postsSectionKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(myPageProvider);
    final playlistModel = ref.watch(playlistProvider);
    final playlistCount = playlistModel.ready ? '${playlistModel.playlists.length}' : '—';
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
          refreshAfterAccountChange(ref);
          if (!context.mounted) return;
          Navigator.popUntil(context, ModalRoute.withName('/'));
        },
      ),
      body: CustomScrollView(
          controller: _scrollController,
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
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _ProfileStatsBar(
                        postCount: postCount,
                        likedCount: likedCount,
                        playlistCount: playlistCount,
                        onPosts: _scrollToPosts,
                        onLiked: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LikedPostsPage()),
                          );
                        },
                        onPlaylists: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PlaylistPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, thickness: 0.5, color: Color(0xFFEFF3F4)),
                  ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              key: _postsSectionKey,
              child: const SizedBox.shrink(),
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
                      onAfterDetailVisit: model.refreshViewCountForPost,
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

class _ProfileStatsBar extends StatelessWidget {
  const _ProfileStatsBar({
    required this.postCount,
    required this.likedCount,
    required this.playlistCount,
    required this.onPosts,
    required this.onLiked,
    required this.onPlaylists,
  });

  final String postCount;
  final String likedCount;
  final String playlistCount;
  final VoidCallback onPosts;
  final VoidCallback onLiked;
  final VoidCallback onPlaylists;

  static const _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _ProfileStatCell(
                value: postCount,
                label: '投稿',
                hint: '一覧へ',
                onTap: onPosts,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: _border),
            Expanded(
              child: _ProfileStatCell(
                value: likedCount,
                label: 'いいね',
                hint: '見る',
                onTap: onLiked,
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: _border),
            Expanded(
              child: _ProfileStatCell(
                value: playlistCount,
                label: 'プレイリスト',
                hint: '見る',
                onTap: onPlaylists,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatCell extends StatelessWidget {
  const _ProfileStatCell({
    required this.value,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final String value;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: mainColor.withValues(alpha: 0.08),
        highlightColor: mainColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: _MyPageState._primaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _MyPageState._secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: mainColor,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, size: 16, color: mainColor),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
