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
import '../share/lyric_share_page.dart';
import 'swipe_deck.dart';
import 'timeline_filter_sheet.dart';
import 'timeline_sort.dart';
import 'timeline_controls_tutorial.dart';

class TimelinePage extends ConsumerStatefulWidget {
  const TimelinePage({super.key, this.isActive = true});

  /// HomePage は IndexedStack に全タブを保持するため、選択中のときだけ true。
  final bool isActive;

  @override
  ConsumerState<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<TimelinePage> {
  /// デフォルトはカード（スワイプ）表示。
  var _deck = true;
  var _tutorialCheckScheduled = false;
  final _autoplayTutorialKey = GlobalKey();
  final _sortTutorialKey = GlobalKey();
  final _filterTutorialKey = GlobalKey();
  final _viewTutorialKey = GlobalKey();
  final _cardTutorialKey = GlobalKey();

  Future<void> _playCardPreview(Post post) async {
    await ref.read(cardPreviewPlayerProvider).playForPost(post);
  }

  Future<void> _toggleTimelinePreview(Post post) async {
    final player = ref.read(cardPreviewPlayerProvider);
    if (player.playingPostId == post.id && player.isPlaying) {
      await player.stop();
      return;
    }
    await player.playForPost(post);
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(timelineProvider);
    final previewPlayer = ref.watch(cardPreviewPlayerProvider);
    final posts = model.visiblePosts;

    final notificationUnread = ref.watch(
      notificationInboxProvider.select((m) => m.unreadCount),
    );

    if (widget.isActive && _deck && !_tutorialCheckScheduled) {
      _tutorialCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (!widget.isActive || !_deck) {
          _tutorialCheckScheduled = false;
          return;
        }
        unawaited(
          TimelineControlsTutorial.showIfNeeded(
            context,
            uid: ref.read(timelineProvider).uid,
            targets: [
              _cardTutorialKey,
              _autoplayTutorialKey,
              _sortTutorialKey,
              _filterTutorialKey,
              _viewTutorialKey,
            ],
          ),
        );
      });
    }

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
                    key: _autoplayTutorialKey,
                    enabled: ref.watch(cardAutoplaySettingsProvider).enabled,
                    onToggle: () async {
                      final settings = ref.read(cardAutoplaySettingsProvider);
                      final next = !settings.enabled;
                      await settings.setEnabled(next);
                      if (!next)
                        await ref.read(cardPreviewPlayerProvider).stop();
                    },
                  ),
                _SortButton(
                  key: _sortTutorialKey,
                  sortOrder: model.sortOrder,
                  onSelected: (order) => model.setSortOrder(order),
                ),
                _FilterButton(
                  key: _filterTutorialKey,
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
                  key: _viewTutorialKey,
                  deck: _deck,
                  onChanged: (deck) {
                    if (!deck) ref.read(cardPreviewPlayerProvider).stop();
                    setState(() => _deck = deck);
                  },
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationPage(),
                      ),
                    );
                    if (!mounted) return;
                    await ref.read(notificationInboxProvider).load();
                  },
                  icon: _NotificationBellIcon(unread: notificationUnread),
                ),
              ],
            ),
          ),
          _TimelineGenreTabs(
            genres: model.availableFilterGenres.toList(growable: false),
            selectedGenre: model.filter.genres.length == 1
                ? model.filter.genres.first
                : null,
            allSelected: model.filter.genres.isEmpty,
            onSelected: (genre) =>
                unawaited(_selectTimelineGenre(model, genre)),
            onSwipe: (direction) => _stepTimelineGenre(model, direction),
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
          if (model.filter.songArtist?.trim().isNotEmpty == true ||
              model.filter.genres.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Material(
                color: const Color(0xFFFFF1F5),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.music_note_rounded,
                        color: mainColor,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          model.filter.songArtist?.trim().isNotEmpty == true
                              ? '歌手「${model.filter.songArtist}」で絞り込み中'
                              : 'ジャンル「${model.filter.genres.join('・')}」で絞り込み中',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF59434B),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => model.setFilter(
                          model.filter.copyWith(
                            genres: const {},
                            clearSongArtist: true,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: mainColor,
                          minimumSize: const Size(52, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('解除'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _deck
                ? SwipeDeck(
                    key: _cardTutorialKey,
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
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(post.id, false),
                        ),
                      );
                    },
                    onOpenUser: (post) {
                      openUserProfile(
                        context,
                        posterId: post.posterId,
                        userName: post.userName,
                      );
                    },
                    onFilterArtist: (artist) => model.setFilter(
                      model.filter.copyWith(
                        genres: const {},
                        songArtist: artist,
                      ),
                    ),
                    onFilterGenre: (genre) => model.setFilter(
                      model.filter.copyWith(
                        genres: {genre},
                        clearSongArtist: true,
                      ),
                    ),
                    onPlay: _playCardPreview,
                    onShare: (post) => unawaited(
                      openLyricShare(
                      context,
                      LyricShareData(
                        lyrics: post.text,
                        title: post.singName,
                        artist: post.artist,
                        genres: post.genres.whereType<String>().toList(),
                      ),
                      ),
                    ),
                    onAddToPlaylist: (post) =>
                        _pickPlaylist(context, model, post),
                    onNeedMore: model.loadMorePosts,
                    onStopPreview: () =>
                        ref.read(cardPreviewPlayerProvider).stop(),
                    onForegroundCard: (post) async {
                      if (!ref.read(cardAutoplaySettingsProvider).enabled)
                        return;
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
                                child: CircularProgressIndicator(
                                  color: mainColor,
                                ),
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
                                  if (model.filter.isActive ||
                                      model.sortOrder !=
                                          TimelineSortOrder.newest)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        8,
                                        16,
                                        4,
                                      ),
                                      child: Text(
                                        model.filter.isActive
                                            ? model.filterBannerText(
                                                posts.length,
                                              )
                                            : '${posts.length}件 · ${model.sortOrder.label}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF536471),
                                        ),
                                      ),
                                    ),
                                  for (final post in posts)
                                    LyricPostCard(
                                      post: post,
                                      showPostTime: false,
                                      onPlay: _toggleTimelinePreview,
                                      isPlaying:
                                          previewPlayer.playingPostId ==
                                              post.id &&
                                          previewPlayer.isPlaying,
                                      onPlaylist: () =>
                                          _pickPlaylist(context, model, post),
                                      menuItems: post.posterId == model.uid
                                          ? const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('編集する'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('削除する'),
                                              ),
                                            ]
                                          : const [
                                              PopupMenuItem(
                                                value: 'report',
                                                child: Text('報告する'),
                                              ),
                                              PopupMenuItem(
                                                value: 'block',
                                                child: Text('ブロックする'),
                                              ),
                                            ],
                                      onMenu: (value) => _onPostMenu(
                                        context,
                                        model,
                                        post,
                                        value,
                                      ),
                                    ),
                                ],
                              ),
                            if (model.loadingMore)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: CircularProgressIndicator(
                                  color: mainColor,
                                ),
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

  Future<void> _selectTimelineGenre(dynamic model, String? genre) async {
    if (genre == null && model.filter.genres.isEmpty) return;
    if (genre != null &&
        model.filter.genres.length == 1 &&
        model.filter.genres.contains(genre)) {
      return;
    }
    await model.setFilter(
      model.filter.copyWith(genres: genre == null ? <String>{} : {genre}),
    );
  }

  void _stepTimelineGenre(dynamic model, int direction) {
    final genres = model.availableFilterGenres.toList(growable: false);
    final tabs = <String?>[null, ...genres];
    final current = model.filter.genres.length == 1
        ? model.filter.genres.first
        : null;
    final currentIndex = tabs.indexOf(current);
    final nextIndex = (currentIndex + direction)
        .clamp(0, tabs.length - 1)
        .toInt();
    if (nextIndex == currentIndex) return;
    unawaited(_selectTimelineGenre(model, tabs[nextIndex]));
  }

  Future<void> _onPostMenu(
    BuildContext context,
    dynamic model,
    dynamic post,
    String value,
  ) async {
    if (value == 'delete') {
      final ok = await showAppConfirm(
        context,
        title: '投稿を削除',
        message: 'この投稿を削除しますか？',
        confirm: '削除する',
        destructive: true,
      );
      if (ok) await model.deletePosts(post.id);
    } else if (value == 'block') {
      final ok = await showAppConfirm(
        context,
        title: 'ブロック',
        message: 'このユーザーをブロックしますか？',
        confirm: 'ブロックする',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await ref.read(blockListProvider).blockUser(post.posterId);
      ref.read(timelineProvider).removePostsByPoster(post.posterId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ブロックしました')));
    } else if (value == 'report') {
      final ok = await showAppConfirm(
        context,
        title: '報告',
        message: 'この投稿を報告しますか？',
        confirm: '報告する',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await model.reportPosts(post.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('報告しました')));
    } else if (value == 'edit') {
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
  }

  Future<bool> _pickPlaylist(
    BuildContext context,
    dynamic model,
    dynamic post,
  ) {
    return showPlaylistPickerSheet(
      context,
      playlists: model.playList,
      onSelect: (playlistId) async {
        await model.addToPlaylist(
          playlistId,
          post.artist,
          post.singName,
          post.youtubeLink,
          post.id,
        );
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
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineGenreTabs extends StatefulWidget {
  const _TimelineGenreTabs({
    required this.genres,
    required this.selectedGenre,
    required this.allSelected,
    required this.onSelected,
    required this.onSwipe,
  });

  final List<String> genres;
  final String? selectedGenre;
  final bool allSelected;
  final ValueChanged<String?> onSelected;
  final ValueChanged<int> onSwipe;

  @override
  State<_TimelineGenreTabs> createState() => _TimelineGenreTabsState();
}

class _TimelineGenreTabsState extends State<_TimelineGenreTabs> {
  final _scrollController = ScrollController();
  final _pointerStarts = <int, Offset>{};

  double _tabWidth(String? genre) =>
      ((genre?.length ?? 3) * 14.0 + 28).clamp(72.0, 190.0).toDouble();

  void _keepSelectedVisible() {
    if (!_scrollController.hasClients) return;
    final selected = widget.allSelected ? null : widget.selectedGenre;
    final genreIndex = selected == null ? -1 : widget.genres.indexOf(selected);
    if (selected != null && genreIndex < 0) return;
    final index = selected == null ? 0 : genreIndex + 1;
    final tabs = <String?>[null, ...widget.genres];
    var leadingWidth = 0.0;
    for (var i = 0; i < index; i++) {
      leadingWidth += _tabWidth(tabs[i]);
    }
    final target = leadingWidth + _tabWidth(tabs[index]) / 2 -
        _scrollController.position.viewportDimension / 2;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent).toDouble(),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

  @override
  void didUpdateWidget(covariant _TimelineGenreTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedGenre != widget.selectedGenre ||
        oldWidget.allSelected != widget.allSelected ||
        oldWidget.genres.length != widget.genres.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _keepSelectedVisible();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <String?>[null, ...widget.genres];
    return Container(
      height: 46,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFECECF0))),
      ),
      child: Listener(
        onPointerDown: (event) => _pointerStarts[event.pointer] = event.position,
        onPointerCancel: (event) => _pointerStarts.remove(event.pointer),
        onPointerUp: (event) {
          final start = _pointerStarts.remove(event.pointer);
          if (start == null) return;
          final delta = event.position - start;
          if (delta.dx.abs() > 48 && delta.dx.abs() > delta.dy.abs() * 1.25) {
            widget.onSwipe(delta.dx < 0 ? 1 : -1);
          }
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: tabs.length,
          itemBuilder: (context, index) {
            final genre = tabs[index];
            final selected = genre == null
                ? widget.allSelected
                : genre == widget.selectedGenre;
            return InkWell(
              onTap: () => widget.onSelected(genre),
              child: SizedBox(
                width: _tabWidth(genre),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 2),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? mainColor : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    genre ?? 'すべて',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? const Color(0xFF25242A)
                          : const Color(0xFF777781),
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardPreviewToggle extends StatelessWidget {
  const _CardPreviewToggle({
    super.key,
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
    super.key,
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
  const _FilterButton({
    super.key,
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            Icons.tune_rounded,
            color: active ? mainColor : const Color(0xFF1C1C1E),
          ),
          if (active)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: mainColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
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
        child: Icon(
          icon,
          size: 18,
          color: selected ? mainColor : const Color(0xFF536471),
        ),
      ),
    );
  }
}
