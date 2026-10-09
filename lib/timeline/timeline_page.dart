import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';
import 'package:str_gram_beta/common/open_user_profile.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
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
import 'timeline_model.dart';
import 'timeline_sort.dart';
class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  /// デフォルトはカード（スワイプ）表示。
  var _deck = true;

  @override
  void dispose() {
    ref.read(cardPreviewPlayerProvider).stop();
    super.dispose();
  }

  Future<void> _playCardPreview(Post post) async {
    await ref.read(cardPreviewPlayerProvider).playForPost(post);
  }

  Future<void> _refreshTimeline(TimelineModel model) async {
    try {
      await model.getFirstPostData();
    } catch (e, st) {
      debugPrint('Timeline refresh failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(timelineProvider);
    final posts = model.visiblePosts;

    final notificationUnread = ref.watch(notificationInboxProvider.select((m) => m.unreadCount));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenTop(
            showBack: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_deck)
                  _CardPreviewToggle(
                    enabled: ref.watch(cardAutoplaySettingsProvider).enabled,
                    onToggle: () async {
                      final settings = ref.read(cardAutoplaySettingsProvider);
                      final next = !settings.enabled;
                      await settings.setEnabled(next);
                      if (!next) await ref.read(cardPreviewPlayerProvider).stop();
                    },
                  ),
                _SortButton(
                  sortOrder: model.sortOrder,
                  onSelected: (order) => model.setSortOrder(order),
                ),
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
                  onChanged: (deck) {
                    if (!deck) ref.read(cardPreviewPlayerProvider).stop();
                    setState(() => _deck = deck);
                  },
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                    if (!mounted) return;
                    await ref.read(notificationInboxProvider).load();
                  },
                  icon: _NotificationBellIcon(unread: notificationUnread),
                ),
              ],
            ),
          ),
          if (model.filter.isActive && model.filterApplying)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: LinearProgressIndicator(color: mainColor, minHeight: 2),
            ),
          if (model.filterLoadError != null || model.sortLoadError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                model.filterLoadError ?? model.sortLoadError!,
                style: const TextStyle(fontSize: 13, color: Color(0xFFCF6679)),
              ),
            ),
          if (model.filterClientGenreFallback &&
              model.filterLoadError == null &&
              model.filter.isActive)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text(
                'ジャンル絞り込みを端末側で実行しています（Firestore インデックス待ち）。',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: mainColor,
              onRefresh: () => _refreshTimeline(model),
              child: _deck
                  ? CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: SwipeDeck(
                            posts: [
                              for (final post in posts)
                                if (model.isVisibleInSwipeDeck(post)) post,
                            ],
                            likedIds: model.likedPostIds,
                            loadingMore: model.loadingMore,
                            hasMore: model.hasMorePosts,
                            onLike: (post) => model.likePost(post.id),
                            onDismiss: (id) => unawaited(model.markSwipeSeen(id)),
                            onOpen: (post) async {
                              await Navigator.push<void>(
                                context,
                                MaterialPageRoute(builder: (_) => PostDetailPage(post.id, false)),
                              );
                              await model.refreshViewCountForPost(post.id);
                            },
                            onOpenUser: (post) {
                              openUserProfile(context, posterId: post.posterId, userName: post.userName);
                            },
                            onPlay: _playCardPreview,
                            onAddToPlaylist: (post) => _pickPlaylist(context, model, post),
                            onNeedMore: model.loadMorePosts,
                            onStopPreview: () => ref.read(cardPreviewPlayerProvider).stop(),
                            onForegroundCard: (post) async {
                              await model.recordViewForPost(post);
                              if (!ref.read(cardAutoplaySettingsProvider).enabled) return;
                              await _playCardPreview(post);
                            },
                          ),
                        ),
                      ],
                    )
                  : NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        final metrics = notification.metrics;
                        if (metrics.pixels > metrics.maxScrollExtent - 480) {
                          model.loadMorePosts();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        slivers: [
                          if (!model.postsReady)
                            const SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(child: CircularProgressIndicator(color: mainColor)),
                            )
                          else if (posts.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: EmptyState(
                                message: model.filterLoadError != null
                                    ? '絞り込みを読み込めませんでした'
                                    : model.filter.isActive
                                        ? '条件に合う投稿がありません'
                                        : 'まだ歌詞の投稿がありません',
                                detail: model.filterLoadError,
                              ),
                            )
                          else ...[
                            if (model.filter.isActive || model.sortOrder != TimelineSortOrder.newest)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                  child: Text(
                                    model.filter.isActive
                                        ? model.filterBannerText(posts.length)
                                        : '${posts.length}件 · ${model.sortOrder.label}',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF536471)),
                                  ),
                                ),
                              ),
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final post = posts[index];
                                  return LyricPostCard(
                                    post: post,
                                    onAfterDetailVisit: model.refreshViewCountForPost,
                                    trackFeedView: true,
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
                                  );
                                },
                                childCount: posts.length,
                              ),
                            ),
                          ],
                          if (model.loadingMore)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(color: mainColor)),
                              ),
                            ),
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
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
      await ref.read(blockListProvider).blockUser(post.posterId);
      ref.read(timelineProvider).removePostsByPoster(post.posterId);
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

  Future<bool> _pickPlaylist(BuildContext context, dynamic model, dynamic post) {
    return showPlaylistPickerSheet(
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

class _NotificationBellIcon extends StatelessWidget {
  const _NotificationBellIcon({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final hasUnread = unread > 0;
    final icon = Icon(
      hasUnread ? Icons.notifications_rounded : Icons.notifications_none,
      color: hasUnread ? mainColor : const Color(0xFF1C1C1E),
    );
    if (!hasUnread) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              unread > 99 ? '99+' : '$unread',
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white, height: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _CardPreviewToggle extends StatelessWidget {
  const _CardPreviewToggle({
    required this.enabled,
    required this.onToggle,
  });

  final bool enabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: enabled ? 'カード自動再生 ON' : 'カード自動再生 OFF',
      onPressed: onToggle,
      icon: Icon(
        enabled ? Icons.music_note_rounded : Icons.music_off_rounded,
        color: enabled ? mainColor : const Color(0xFF8E8E93),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sortOrder,
    required this.onSelected,
  });

  final TimelineSortOrder sortOrder;
  final ValueChanged<TimelineSortOrder> onSelected;

  @override
  Widget build(BuildContext context) {
    final highlighted = sortOrder != TimelineSortOrder.newest;
    return PopupMenuButton<TimelineSortOrder>(
      tooltip: '並び替え',
      onSelected: onSelected,
      icon: Icon(
        Icons.sort_rounded,
        color: highlighted ? mainColor : const Color(0xFF1C1C1E),
      ),
      itemBuilder: (context) => [
        for (final order in TimelineSortOrder.values)
          CheckedPopupMenuItem(
            value: order,
            checked: sortOrder == order,
            child: Text(order.label),
          ),
      ],
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
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.tune_rounded, color: active ? mainColor : const Color(0xFF1C1C1E)),
          if (active)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: mainColor, shape: BoxShape.circle),
              ),
            ),
        ],
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
