import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/auth/anonymous_user.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/common/swipe_card_scene.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/timeline/card_lyrics_pane.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/timeline/swipe_deck_tutorial_cue.dart';

const _kCardHorizontal = 16.0;
const _kCardRailWidth = 52.0;

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.posts,
    required this.likedIds,
    required this.onLike,
    this.onScrollPast,
    required this.onOpen,
    required this.onOpenUser,
    required this.onFilterArtist,
    required this.onFilterGenre,
    required this.onPlay,
    required this.onShare,
    required this.onComment,
    required this.onAddToPlaylist,
    required this.onNeedMore,
    required this.loadingMore,
    required this.hasMore,
    this.onForegroundCard,
    this.onStopPreview,
    this.swipeCue,
    this.onCreatePost,
  });

  final List<Post> posts;
  final Set<String> likedIds;
  final Future<void> Function(Post post) onLike;
  /// 下方向へスクロールして通過した投稿（フィードからは消さない）。
  final void Function(String id)? onScrollPast;
  final void Function(Post post) onOpen;
  final void Function(Post post) onOpenUser;
  final void Function(String artist) onFilterArtist;
  final void Function(String genre) onFilterGenre;
  final void Function(Post post) onPlay;
  final void Function(Post post) onShare;
  final void Function(Post post) onComment;

  /// プレイリストに追加できたら true。
  final Future<bool> Function(Post post) onAddToPlaylist;
  final VoidCallback onNeedMore;
  final bool loadingMore;
  final bool hasMore;

  /// 手前のカードが変わったとき（自動再生など）。
  final Future<void> Function(Post post)? onForegroundCard;
  final VoidCallback? onStopPreview;
  final SwipeDeckTutorialCue? swipeCue;
  final VoidCallback? onCreatePost;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with TickerProviderStateMixin {
  late final PageController _pageController;
  var _pageIndex = 0;
  String? _focusedPostId;
  String? _foregroundNotifiedId;
  var _verticalDragAccum = 0.0;

  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(() => setState(() {}));

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.posts.isNotEmpty) {
      _focusedPostId = widget.posts.first.id;
    }
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _notifyForegroundIfNeeded(),
    );
  }

  void _notifyForegroundIfNeeded() {
    final posts = widget.posts;
    if (posts.isEmpty || widget.onForegroundCard == null || _onEndPage) return;
    final index = _pageIndex.clamp(0, posts.length - 1);
    final post = posts[index];
    if (_foregroundNotifiedId == post.id) return;
    _foregroundNotifiedId = post.id;
    unawaited(widget.onForegroundCard!(post));
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final posts = widget.posts;
    if (posts.isEmpty) {
      _pageIndex = 0;
      _focusedPostId = null;
      return;
    }

    var targetIndex = _pageIndex;
    if (_focusedPostId != null) {
      final byId = posts.indexWhere((p) => p.id == _focusedPostId);
      if (byId >= 0) {
        targetIndex = byId;
      } else {
        targetIndex = _pageIndex.clamp(0, posts.length - 1);
        _focusedPostId = posts[targetIndex].id;
      }
    } else {
      targetIndex = _pageIndex.clamp(0, posts.length - 1);
      _focusedPostId = posts[targetIndex].id;
    }

    final maxIndex = _pageCount - 1;
    if (targetIndex > maxIndex) targetIndex = maxIndex;

    if (targetIndex != _pageIndex) {
      _pageIndex = targetIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        final jump = _pageIndex.clamp(0, _pageCount - 1);
        if (_pageController.page?.round() != jump) {
          _pageController.jumpToPage(jump);
        }
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  int get _pageCount => widget.posts.length + 1;

  bool get _onEndPage => _pageIndex >= widget.posts.length;

  void _onPageChanged(int index) {
    final posts = widget.posts;
    final prev = _pageIndex;

    if (index < posts.length &&
        index > prev &&
        prev < posts.length &&
        widget.onScrollPast != null) {
      for (var i = prev; i < index; i++) {
        widget.onScrollPast!(posts[i].id);
      }
    }
    if (index == posts.length && prev < posts.length && widget.onScrollPast != null) {
      widget.onScrollPast!(posts[prev].id);
    }

    _pageIndex = index;
    if (index < posts.length) {
      _focusedPostId = posts[index].id;
      _foregroundNotifiedId = null;
      _notifyForegroundIfNeeded();
      if (index >= posts.length - 2 && widget.hasMore && !widget.loadingMore) {
        widget.onNeedMore();
      }
    } else {
      _focusedPostId = null;
      widget.onStopPreview?.call();
    }
  }

  Future<void> _animateToPage(int index) async {
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _pageNext() async {
    if (_pageIndex >= _pageCount - 1) return;
    await _animateToPage(_pageIndex + 1);
  }

  Future<void> _pagePrevious() async {
    if (_pageIndex <= 0) return;
    await _animateToPage(_pageIndex - 1);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (_verticalDragAccum < -52 || velocity < -520) {
      unawaited(_pageNext());
    } else if (_verticalDragAccum > 52 || velocity > 520) {
      unawaited(_pagePrevious());
    }
    _verticalDragAccum = 0;
  }

  Future<void> _onLikeTap(Post post) async {
    HapticFeedback.mediumImpact();
    unawaited(_celebrate.forward(from: 0));
    await widget.onLike(post);
    if (mounted) _celebrate.reset();
  }

  Future<void> _onPlaylistTap(Post post) async {
    await widget.onAddToPlaylist(post);
  }

  @override
  Widget build(BuildContext context) {
    final posts = widget.posts;
    if (posts.isEmpty) {
      if (widget.hasMore && !widget.loadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onNeedMore();
        });
      }
      return Center(
        child: widget.loadingMore || widget.hasMore
            ? const CircularProgressIndicator(color: mainColor)
            : const Text(
                '歌詞はここまでです',
                style: TextStyle(color: Color(0xFF8E8E93)),
              ),
      );
    }

    Widget deck = PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const NeverScrollableScrollPhysics(),
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: _pageCount,
      itemBuilder: (context, index) {
        if (index >= posts.length) {
          return _DeckEndCard(
            loadingMore: widget.loadingMore,
            hasMore: widget.hasMore,
            onCreatePost: widget.onCreatePost,
          );
        }
        final post = posts[index];
        final liked = widget.likedIds.contains(post.id);
        return _LyricCard(
          post: post,
          liked: liked,
          celebrate: _celebrate,
          onOpen: () => widget.onOpen(post),
          onOpenUser: () => widget.onOpenUser(post),
          onFilterArtist: widget.onFilterArtist,
          onFilterGenre: widget.onFilterGenre,
          onPlay: () => widget.onPlay(post),
          onComment: () => widget.onComment(post),
          onLike: () => _onLikeTap(post),
          onShare: () => widget.onShare(post),
          onPlaylist: () => _onPlaylistTap(post),
        );
      },
    );

    deck = GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: (details) {
        _verticalDragAccum += details.delta.dy;
      },
      onVerticalDragEnd: _onVerticalDragEnd,
      child: deck,
    );

    final cue = widget.swipeCue;
    if (cue != null) {
      deck = ListenableBuilder(
        listenable: cue,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, cue.dragDy),
            child: child,
          );
        },
        child: deck,
      );
    }

    return deck;
  }
}

class _DeckEndCard extends StatelessWidget {
  const _DeckEndCard({
    required this.loadingMore,
    required this.hasMore,
    this.onCreatePost,
  });

  final bool loadingMore;
  final bool hasMore;
  final VoidCallback? onCreatePost;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lyrics_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 20),
              Text(
                hasMore || loadingMore
                    ? '読み込み中…'
                    : 'ここまで表示しました',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                hasMore || loadingMore
                    ? '少し待ってから、もう一度スワイプしてみてください'
                    : 'あなたの好きな歌詞も投稿して、みんなと共有しましょう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              if (loadingMore) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: mainColor),
              ] else if (!hasMore && onCreatePost != null) ...[
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                  ),
                  onPressed: onCreatePost,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('歌詞を投稿する'),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '下にスワイプで前のカードに戻れます',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideActionRail extends StatelessWidget {
  const _SideActionRail({
    required this.commentCount,
    required this.likeCount,
    required this.liked,
    required this.celebrate,
    required this.onComment,
    required this.onLike,
    required this.onShare,
    required this.onPlaylist,
  });

  final int commentCount;
  final int likeCount;
  final bool liked;
  final AnimationController celebrate;
  final VoidCallback onComment;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onPlaylist;

  String _countLabel(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SideActionButton(
          icon: Icons.chat_bubble_outline_rounded,
          label: commentCount > 0 ? _countLabel(commentCount) : null,
          onTap: onComment,
        ),
        const SizedBox(height: 20),
        _SideLikeButton(
          liked: liked,
          label: likeCount > 0 ? _countLabel(likeCount) : null,
          celebrate: celebrate,
          onTap: onLike,
        ),
        const SizedBox(height: 20),
        _SideActionButton(
          icon: Icons.ios_share_rounded,
          onTap: onShare,
        ),
        const SizedBox(height: 16),
        _SideActionButton(
          icon: Icons.playlist_add_rounded,
          onTap: onPlaylist,
        ),
      ],
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.icon,
    this.label,
    required this.onTap,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Icon(icon, color: Colors.white, size: 30, shadows: _ink),
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.1,
              shadows: _ink,
            ),
          ),
        ],
      ],
    );
  }
}

class _SideLikeButton extends StatelessWidget {
  const _SideLikeButton({
    required this.liked,
    required this.celebrate,
    this.label,
    required this.onTap,
  });

  final bool liked;
  final AnimationController celebrate;
  final String? label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrate,
      builder: (context, child) {
        final t = celebrate.value;
        final pop = t > 0 ? 1 + 0.12 * math.sin(t * math.pi) : 1.0;
        final heartFilled = liked || t > 0.25;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: pop,
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  heartFilled
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: heartFilled ? mainColor : Colors.white,
                  size: 30,
                  shadows: _ink,
                ),
              ),
            ),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                  shadows: _ink,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DeckPreviewProgress extends ConsumerWidget {
  const _DeckPreviewProgress({required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(cardPreviewPlayerProvider);
    final active = player.playingPostId == postId;
    final value = active ? player.progressForPost(postId) : 0.0;
    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      backgroundColor: Colors.white.withValues(alpha: 0.22),
      color: mainColor,
    );
  }
}

class _DeckPlayButton extends ConsumerWidget {
  const _DeckPlayButton({
    required this.postId,
    required this.onTap,
    required this.hasPreview,
  });

  final String postId;
  final VoidCallback onTap;
  final bool hasPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasPreview) return const SizedBox.shrink();
    final player = ref.watch(cardPreviewPlayerProvider);
    final isThis = player.playingPostId == postId;
    final playing = isThis && player.isPlaying;
    final loading = isThis && player.loading;

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: mainColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 30,
                ),
        ),
      ),
    );
  }
}

class _LyricCard extends ConsumerWidget {
  const _LyricCard({
    required this.post,
    required this.liked,
    required this.celebrate,
    required this.onOpen,
    required this.onOpenUser,
    required this.onFilterArtist,
    required this.onFilterGenre,
    required this.onPlay,
    required this.onComment,
    required this.onLike,
    required this.onShare,
    required this.onPlaylist,
  });

  final Post post;
  final bool liked;
  final AnimationController celebrate;
  final VoidCallback onOpen;
  final VoidCallback onOpenUser;
  final void Function(String artist) onFilterArtist;
  final void Function(String genre) onFilterGenre;
  final VoidCallback onPlay;
  final VoidCallback onComment;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = post.genres
        .whereType<String>()
        .where((genre) => genre.isNotEmpty)
        .take(3)
        .toList();
    final scene = swipeCardSceneFor(genres);
    return DecoratedBox(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
            child: Image.asset(
              scene,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.38),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.22),
                  Colors.black.withValues(alpha: 0.72),
                ],
                stops: const [0, 0.45, 0.7, 1],
              ),
            ),
          ),
          Positioned(
            left: _kCardHorizontal,
            right: _kCardRailWidth + 8,
            top: 48,
            bottom: 168,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Align(
                  alignment: Alignment.topCenter,
                  child: CardLyricsPane(
                    post: post,
                    maxWidth: constraints.maxWidth,
                    maxHeight: constraints.maxHeight,
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        _kCardHorizontal,
                        14,
                        _kCardRailWidth + 12,
                        6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white.withValues(alpha: 0.14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    color: Colors.white70,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: onOpen,
                                        borderRadius: BorderRadius.circular(4),
                                        child: Text(
                                          post.singName,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: _titleStyle,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Tooltip(
                                      message: 'この歌手の投稿に絞り込む',
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () =>
                                              onFilterArtist(post.artist),
                                          borderRadius: BorderRadius.circular(4),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  post.artist,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: _subStyle,
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                size: 16,
                                                color: Colors.white
                                                    .withValues(alpha: 0.72),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (genres.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final genre in genres)
                                  GestureDetector(
                                    onTap: () => onFilterGenre(genre),
                                    child: Text(
                                      genre,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shadows: _ink,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onOpenUser,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFFFFE4EC),
                                  backgroundImage:
                                      post.userImageUrl.isEmpty ||
                                              post.userImageUrl == 'null'
                                          ? null
                                          : NetworkImage(post.userImageUrl),
                                  child: post.userImageUrl.isEmpty ||
                                          post.userImageUrl == 'null'
                                      ? const Icon(
                                          Icons.person,
                                          size: 14,
                                          color: mainColor,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    publicDisplayName(post.userName),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      shadows: _ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _DeckPreviewProgress(postId: post.id),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 88,
            child: SafeArea(
              top: false,
              child: ListenUrlPlaySlot(
                storedUrl: post.youtubeLink,
                artist: post.artist,
                singName: post.singName,
                builder: (context, listenUrl) {
                  final hasPreview =
                      listenUrl != null && listenUrl.isNotEmpty;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SideActionRail(
                        commentCount: post.commentCount,
                        likeCount: post.likedCount,
                        liked: liked,
                        celebrate: celebrate,
                        onComment: onComment,
                        onLike: onLike,
                        onShare: onShare,
                        onPlaylist: onPlaylist,
                      ),
                      _DeckPlayButton(
                        postId: post.id,
                        onTap: onPlay,
                        hasPreview: hasPreview,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _ink = [
  Shadow(offset: Offset(-0.6, 0), color: Color(0xE6000000)),
  Shadow(offset: Offset(0.6, 0), color: Color(0xE6000000)),
  Shadow(offset: Offset(0, -0.6), color: Color(0xE6000000)),
  Shadow(offset: Offset(0, 0.8), color: Color(0xE6000000)),
  Shadow(blurRadius: 8, color: Color(0x99000000)),
];

const _titleStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  shadows: _ink,
);

const _subStyle = TextStyle(
  fontSize: 15,
  height: 1.4,
  color: Colors.white,
  shadows: _ink,
);
