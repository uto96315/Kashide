import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import 'package:str_gram_beta/auth/anonymous_user.dart';
import 'package:str_gram_beta/common/swipe_card_scene.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/timeline/swipe_deck_tutorial_cue.dart';

const _kCardHorizontal = 16.0;
const _kCardRailWidth = 64.0;

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

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with TickerProviderStateMixin {
  late final PageController _pageController;
  var _pageIndex = 0;
  String? _focusedPostId;
  String? _foregroundNotifiedId;

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
    if (posts.isEmpty || widget.onForegroundCard == null) return;
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

    if (targetIndex != _pageIndex) {
      _pageIndex = targetIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(targetIndex);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    final posts = widget.posts;
    if (index >= posts.length) return;

    if (index > _pageIndex && widget.onScrollPast != null) {
      for (var i = _pageIndex; i < index; i++) {
        widget.onScrollPast!(posts[i].id);
      }
    }

    _pageIndex = index;
    _focusedPostId = posts[index].id;
    _foregroundNotifiedId = null;
    _notifyForegroundIfNeeded();

    if (index >= posts.length - 2 && widget.hasMore && !widget.loadingMore) {
      widget.onNeedMore();
    }
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

    final deck = PageView.builder(
      scrollDirection: Axis.vertical,
      physics: const PageScrollPhysics(parent: ClampingScrollPhysics()),
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final liked = widget.likedIds.contains(post.id);
        return GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: () => widget.onOpen(post),
          child: _LyricCard(
            post: post,
            liked: liked,
            celebrate: _celebrate,
            onOpenUser: () => widget.onOpenUser(post),
            onFilterArtist: widget.onFilterArtist,
            onFilterGenre: widget.onFilterGenre,
            onPlay: () => widget.onPlay(post),
            onComment: () => widget.onComment(post),
            onLike: () => _onLikeTap(post),
            onShare: () => widget.onShare(post),
            onPlaylist: () => _onPlaylistTap(post),
          ),
        );
      },
    );

    final cue = widget.swipeCue;
    if (cue == null) return deck;

    return ListenableBuilder(
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
        const SizedBox(height: 20),
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
        Material(
          color: Colors.black.withValues(alpha: 0.35),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: Colors.white, size: 26),
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
              child: Material(
                color: Colors.black.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      heartFilled
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: heartFilled ? mainColor : Colors.white,
                      size: 28,
                    ),
                  ),
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

class _LyricCard extends StatelessWidget {
  const _LyricCard({
    required this.post,
    required this.liked,
    required this.celebrate,
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
  final VoidCallback onOpenUser;
  final void Function(String artist) onFilterArtist;
  final void Function(String genre) onFilterGenre;
  final VoidCallback onPlay;
  final VoidCallback onComment;
  final VoidCallback onLike;
  final VoidCallback onShare;
  final VoidCallback onPlaylist;

  @override
  Widget build(BuildContext context) {
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
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x99000000),
                  Color(0x55000000),
                  Color(0x77000000),
                  Color(0xCC000000),
                ],
                stops: [0, 0.35, 0.72, 1],
              ),
            ),
          ),
          Positioned(
            left: _kCardHorizontal,
            right: _kCardRailWidth + 8,
            top: 56,
            bottom: 168,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const pad = 14.0;
                return Align(
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(pad, pad, pad, 12),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.center,
                            child: PostLyricsText.fromPost(
                              post,
                              style: _lyricStyle,
                              textAlign: TextAlign.left,
                              tuneLineBreaks: true,
                              layoutMaxWidth: constraints.maxWidth - pad * 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: _kCardHorizontal,
            right: _kCardRailWidth + 8,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        post.singName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle,
                      ),
                      const SizedBox(height: 2),
                      Tooltip(
                        message: 'この歌手の投稿に絞り込む',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => onFilterArtist(post.artist),
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      post.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _subStyle.copyWith(color: Colors.white),
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.72),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (genres.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final genre in genres)
                              Material(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => onFilterGenre(genre),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      genre,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFFFFE4EC),
                            backgroundImage:
                                post.userImageUrl.isEmpty ||
                                        post.userImageUrl == 'null'
                                    ? null
                                    : NetworkImage(post.userImageUrl),
                            child:
                                post.userImageUrl.isEmpty ||
                                        post.userImageUrl == 'null'
                                    ? const Icon(
                                        Icons.person,
                                        size: 18,
                                        color: mainColor,
                                      )
                                    : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: onOpenUser,
                              child: Text(
                                publicDisplayName(post.userName),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
                                  shadows: _ink,
                                ),
                              ),
                            ),
                          ),
                          ListenUrlPlaySlot(
                            storedUrl: post.youtubeLink,
                            artist: post.artist,
                            singName: post.singName,
                            builder: (context, listenUrl) {
                              if (listenUrl == null || listenUrl.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: onPlay,
                                  customBorder: const CircleBorder(),
                                  child: const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: mainColor,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: 96,
            child: SafeArea(
              top: false,
              child: _SideActionRail(
                commentCount: post.commentCount,
                likeCount: post.likedCount,
                liked: liked,
                celebrate: celebrate,
                onComment: onComment,
                onLike: onLike,
                onShare: onShare,
                onPlaylist: onPlaylist,
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

const _lyricStyle = TextStyle(
  fontSize: 22,
  height: 1.42,
  fontWeight: FontWeight.w600,
  color: Colors.white,
);

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
