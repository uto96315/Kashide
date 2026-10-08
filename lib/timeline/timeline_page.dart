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
import 'timeline_sort.dart';
import 'timeline_tutorial.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key});

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  /// デフォルトはカード（スワイプ）表示。
  var _deck = true;

  int? _tutorialStep;
  var _tutorialLaunchChecked = false;

  final _tutorialTargets = TimelineTutorialTargets(
    viewToggle: GlobalKey(),
    autoplay: GlobalKey(),
    sort: GlobalKey(),
    filter: GlobalKey(),
    swipeCard: GlobalKey(),
    swipeActions: GlobalKey(),
  );

  @override
  void dispose() {
    ref.read(cardPreviewPlayerProvider).stop();
    super.dispose();
  }

  Future<void> _playCardPreview(Post post) async {
    await ref.read(cardPreviewPlayerProvider).playForPost(post);
  }

  Future<void> _tryLaunchTutorial() async {
    if (_tutorialLaunchChecked || _tutorialStep != null) return;
    final model = ref.read(timelineProvider);
    if (!model.postsReady) return;
    _tutorialLaunchChecked = true;
    if (!await TimelineTutorialStorage.shouldShow(model.uid)) return;
    if (!mounted) return;
    setState(() {
      _deck = true;
      _tutorialStep = 0;
    });
  }

  void _advanceTutorial() {
    final step = _tutorialStep;
    if (step == null) return;
    if (step >= timelineTutorialStepCount - 1) {
      unawaited(TimelineTutorialStorage.markComplete(ref.read(timelineProvider).uid));
      setState(() => _tutorialStep = null);
      return;
    }
    setState(() => _tutorialStep = step + 1);
  }

  Future<void> _skipTutorial() async {
    await TimelineTutorialStorage.markComplete(ref.read(timelineProvider).uid);
    if (!mounted) return;
    setState(() => _tutorialStep = null);
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(timelineProvider);
    final posts = model.visiblePosts;

    if (model.postsReady && !_tutorialLaunchChecked && _tutorialStep == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_tryLaunchTutorial()));
    }

    final tutorialStep = _tutorialStep;
    final tutorialActive = tutorialStep != null;
    final notificationUnread = ref.watch(notificationInboxProvider.select((m) => m.unreadCount));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
        children: [
          ScreenTop(
            showBack: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_deck)
                  _CardPreviewToggle(
                    key: tutorialActive ? _tutorialTargets.autoplay : null,
                    enabled: ref.watch(cardAutoplaySettingsProvider).enabled,
                    onToggle: () async {
                      final settings = ref.read(cardAutoplaySettingsProvider);
                      final next = !settings.enabled;
                      await settings.setEnabled(next);
                      if (!next) await ref.read(cardPreviewPlayerProvider).stop();
                    },
                  ),
                _SortButton(
                  key: tutorialActive ? _tutorialTargets.sort : null,
                  sortOrder: model.sortOrder,
                  onSelected: (order) => model.setSortOrder(order),
                ),
                _FilterButton(
                  key: tutorialActive ? _tutorialTargets.filter : null,
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
                  key: tutorialActive ? _tutorialTargets.viewToggle : null,
                  deck: _deck,
                  onChanged: (deck) {
                    if (tutorialActive) return;
                    if (!deck) ref.read(cardPreviewPlayerProvider).stop();
                    setState(() => _deck = deck);
                  },
                ),
                IconButton(
                  tooltip: '通知',
                  onPressed: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationPage()));
                    if (!mounted) return;
                    await ref.read(notificationInboxProvider).load();
                  },
                  icon: Badge(
                    isLabelVisible: notificationUnread > 0,
                    label: Text(
                      notificationUnread > 99 ? '99+' : '$notificationUnread',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    backgroundColor: mainColor,
                    child: Icon(
                      notificationUnread > 0 ? Icons.notifications_rounded : Icons.notifications_none,
                      color: notificationUnread > 0 ? mainColor : const Color(0xFF1C1C1E),
                    ),
                  ),
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
            child: _deck
                ? SwipeDeck(
                    tutorialCardKey: tutorialActive ? _tutorialTargets.swipeCard : null,
                    tutorialActionsKey: tutorialActive ? _tutorialTargets.swipeActions : null,
                    posts: [
                      for (final post in posts)
                        if (model.isVisibleInSwipeDeck(post)) post,
                    ],
                    likedIds: model.likedPostIds,
                    loadingMore: model.loadingMore,
                    hasMore: model.hasMorePosts,
                    onLike: (post) => model.likePost(post.id),
                    onDismiss: (id) => unawaited(model.markSwipeSeen(id)),
                    onOpen: (post) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post.id, false)));
                    },
                    onOpenUser: (post) {
                      openUserProfile(context, posterId: post.posterId, userName: post.userName);
                    },
                    onPlay: _playCardPreview,
                    onAddToPlaylist: (post) => _pickPlaylist(context, model, post),
                    onNeedMore: model.loadMorePosts,
                    onStopPreview: () => ref.read(cardPreviewPlayerProvider).stop(),
                    onForegroundCard: (post) async {
                      if (!ref.read(cardAutoplaySettingsProvider).enabled) return;
                      await _playCardPreview(post);
                    },
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
                                message: model.filterLoadError != null
                                    ? '絞り込みを読み込めませんでした'
                                    : model.filter.isActive
                                        ? '条件に合う投稿がありません'
                                        : 'まだ歌詞の投稿がありません',
                                detail: model.filterLoadError,
                              )
                            else
                              Column(
                                children: [
                                  if (model.filter.isActive || model.sortOrder != TimelineSortOrder.newest)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                      child: Text(
                                        model.filter.isActive
                                            ? model.filterBannerText(posts.length)
                                            : '${posts.length}件 · ${model.sortOrder.label}',
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF536471)),
                                      ),
                                    ),
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
          if (tutorialStep != null)
            Positioned.fill(
              child: TimelineTutorialOverlay(
                step: tutorialStep,
                stepCount: timelineTutorialStepCount,
                title: timelineTutorialTitle(tutorialStep),
                body: timelineTutorialBody(tutorialStep),
                targets: _tutorialTargets,
                onNext: _advanceTutorial,
                onSkip: () => unawaited(_skipTutorial()),
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

class _CardPreviewToggle extends StatelessWidget {
  const _CardPreviewToggle({super.key, required this.enabled, required this.onToggle});

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
  const _SortButton({super.key, required this.sortOrder, required this.onSelected});

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
  const _FilterButton({super.key, required this.active, required this.onPressed});

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
  const _ViewToggle({super.key, required this.deck, required this.onChanged});

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
