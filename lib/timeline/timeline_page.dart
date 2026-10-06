import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';
import 'package:str_gram_beta/common/open_user_profile.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import '../common/ThemeColor.dart';
import '../common/app_dialog.dart';
import '../common/empty_state.dart';
import '../common/playlist_picker_sheet.dart';
import '../common/screen_top.dart';
import '../common/lyric_post_card.dart';
import '../providers.dart';
import 'swipe_deck.dart';
import 'timeline_filter_sheet.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  /// デフォルトはカード（スワイプ）表示。
  var _deck = true;

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(timelineProvider);
    final posts = model.visiblePosts;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenTop(
            showBack: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterButton(
                  active: model.filter.isActive,
                  onPressed: () async {
                    final next = await showTimelineFilterSheet(
                      context,
                      initial: model.filter,
                      availableGenres: model.availableFilterGenres,
                    );
                    if (next != null) await model.setFilter(next);
                  },
                ),
                _ViewToggle(
                  deck: _deck,
                  onChanged: (deck) => setState(() => _deck = deck),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationPage()));
                  },
                  icon: const Icon(Icons.notifications_none),
                ),
              ],
            ),
          ),
          if (model.filter.isActive && model.filterApplying)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: LinearProgressIndicator(color: mainColor, minHeight: 2),
            ),
          Expanded(
            child: _deck
                ? SwipeDeck(
                    posts: [
                      for (final post in posts)
                        if (model.isVisibleInSwipeDeck(post)) post,
                    ],
                    likedIds: model.likedPostIds,
                    loadingMore: model.loadingMore,
                    hasMore: model.hasMorePosts,
                    onLike: (post) => model.likePost(post.id),
                    onDismiss: model.markSwipeSeen,
                    onOpen: (post) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post.id, false)));
                    },
                    onOpenUser: (post) {
                      openUserProfile(context, posterId: post.posterId, userName: post.userName);
                    },
                    onPlay: (post) async {
                      final url = await ref.read(listenUrlResolverProvider).resolvePost(post);
                      if (url != null && url.isNotEmpty) {
                        await model.launchURL(url);
                      }
                    },
                    onAddToPlaylist: (post) => _pickPlaylist(context, model, post),
                    onNeedMore: model.loadMorePosts,
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      final metrics = notification.metrics;
                      if (metrics.pixels > metrics.maxScrollExtent - 480) {
                        model.loadMorePosts();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      color: mainColor,
                      onRefresh: () async {
                        await model.getFirstPostData();
                      },
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            if (!model.postsReady)
                              const Padding(
                                padding: EdgeInsets.only(top: 80),
                                child: CircularProgressIndicator(color: mainColor),
                              )
                            else if (posts.isEmpty)
                              EmptyState(
                                message: model.filter.isActive
                                    ? '条件に合う投稿がありません'
                                    : 'まだ歌詞の投稿がありません',
                              )
                            else
                              Column(
                                children: [
                                  for (final post in posts)
                                    LyricPostCard(
                                      post: post,
                                      onPlaylist: () => _pickPlaylist(context, model, post),
                                      menuItems: post.posterId == model.uid
                                          ? const [
                                              PopupMenuItem(value: 'edit', child: Text('編集する')),
                                              PopupMenuItem(value: 'delete', child: Text('削除する')),
                                            ]
                                          : const [
                                              PopupMenuItem(value: 'report', child: Text('報告する')),
                                              PopupMenuItem(value: 'block', child: Text('ブロックする')),
                                            ],
                                      onMenu: (value) => _onPostMenu(context, model, post, value),
                                    ),
                                ],
                              ),
                            if (model.loadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(color: mainColor),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onPostMenu(BuildContext context, dynamic model, dynamic post, String value) async {
    if (value == 'delete') {
      final ok = await showAppConfirm(context, title: '投稿を削除', message: 'この投稿を削除しますか？', confirm: '削除する', destructive: true);
      if (ok) await model.deletePosts(post.id);
    } else if (value == 'block') {
      final ok = await showAppConfirm(context, title: 'ブロック', message: 'このユーザーをブロックしますか？', confirm: 'ブロックする', destructive: true);
      if (!ok || !context.mounted) return;
      await model.blockUser(post.posterId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ブロックしました')));
    } else if (value == 'report') {
      final ok = await showAppConfirm(context, title: '報告', message: 'この投稿を報告しますか？', confirm: '報告する', destructive: true);
      if (!ok || !context.mounted) return;
      await model.reportPosts(post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報告しました')));
    } else if (value == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => EditPostPage(post.id, post.text, post.artist, post.singName, post.genres, post.explanation, post.youtubeLink)));
    }
  }

  Future<void> _pickPlaylist(BuildContext context, dynamic model, dynamic post) async {
    await showPlaylistPickerSheet(
      context,
      playlists: model.playList,
      onSelect: (playlistId) async {
        await model.addToPlaylist(playlistId, post.artist, post.singName, post.youtubeLink, post.id);
      },
      onCreate: (name) async {
        model.addPlaylistController.text = name;
        model.setNewName(name);
        await model.addNewPlaylist();
        await model.getPlayListData();
        model.addPlaylistController.text = '';
      },
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onPressed});

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Badge(
        isLabelVisible: active,
        smallSize: 8,
        backgroundColor: mainColor,
        child: Icon(Icons.tune_rounded, color: active ? mainColor : const Color(0xFF1C1C1E)),
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.deck, required this.onChanged});

  final bool deck;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _item(Icons.view_agenda_outlined, !deck, () => onChanged(false)),
          _item(Icons.style_outlined, deck, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _item(IconData icon, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 28,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, size: 18, color: selected ? mainColor : const Color(0xFF536471)),
      ),
    );
  }
}
