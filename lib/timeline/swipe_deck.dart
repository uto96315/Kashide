import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:str_gram_beta/common/swipe_card_scene.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/domain/post_domain.dart';

class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.posts,
    required this.likedIds,
    required this.onLike,
    required this.onDismiss,
    required this.onOpen,
    required this.onOpenUser,
    required this.onPlay,
    required this.onAddToPlaylist,
    required this.onNeedMore,
    required this.loadingMore,
    required this.hasMore,
    this.onForegroundCard,
    this.onStopPreview,
  });

  final List<Post> posts;
  final Set<String> likedIds;
  final Future<void> Function(Post post) onLike;
  final void Function(String id) onDismiss;
  final void Function(Post post) onOpen;
  final void Function(Post post) onOpenUser;
  final void Function(Post post) onPlay;
  /// プレイリストに追加できたら true。
  final Future<bool> Function(Post post) onAddToPlaylist;
  final VoidCallback onNeedMore;
  final bool loadingMore;
  final bool hasMore;
  /// 手前のカードが変わったとき（自動再生など）。
  final Future<void> Function(Post post)? onForegroundCard;
  final VoidCallback? onStopPreview;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with TickerProviderStateMixin {
  double _drag = 0;
  double _from = 0;
  double _to = 0;
  var _flying = false;
  String? _foregroundNotifiedId;
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..addListener(() => setState(() {}));

  late final AnimationController _celebrate = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(() => setState(() {}));

  Post? get _post => widget.posts.isEmpty ? null : widget.posts.first;

  double get _dx => _flying ? _from + (_to - _from) * Curves.easeOutCubic.transform(_fly.value) : _drag;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notifyForegroundIfNeeded());
  }

  void _notifyForegroundIfNeeded() {
    final post = _post;
    if (post == null || widget.onForegroundCard == null) return;
    if (_foregroundNotifiedId == post.id) return;
    _foregroundNotifiedId = post.id;
    unawaited(widget.onForegroundCard!(post));
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = oldWidget.posts.isEmpty ? null : oldWidget.posts.first.id;
    final newId = widget.posts.isEmpty ? null : widget.posts.first.id;
    if (oldId != newId) {
      _celebrate.reset();
      _fly.reset();
      _drag = 0;
      _flying = false;
      if (oldId != null) widget.onStopPreview?.call();
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifyForegroundIfNeeded());
    }
  }

  @override
  void dispose() {
    _fly.dispose();
    _celebrate.dispose();
    super.dispose();
  }

  Future<void> _triggerLikeButtonPulse() async {
    await _celebrate.forward(from: 0);
    if (mounted) _celebrate.reset();
  }

  Future<void> _settle(bool? like) async {
    if (_flying || _post == null) return;
    final post = _post!;
    final width = MediaQuery.sizeOf(context).width;
    _from = _drag;
    _to = like == null ? 0 : (like ? width * 1.25 : -width * 1.25);
    _flying = true;
    if (like == true) unawaited(_triggerLikeButtonPulse());
    await _fly.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _drag = 0;
      _flying = false;
    });
    if (like == null) return;
    if (like) {
      await widget.onLike(post);
    } else {
      widget.onDismiss(post.id);
    }
    if (widget.posts.length <= 2 && widget.hasMore) widget.onNeedMore();
  }

  Future<void> _onPlaylistTap(Post post) async {
    if (_flying) return;
    final added = await widget.onAddToPlaylist(post);
    if (!mounted || !added || _flying) return;
    await _settle(true);
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    if (post == null) {
      if (widget.hasMore && !widget.loadingMore) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) widget.onNeedMore();
        });
      }
      return Center(
        child: widget.loadingMore || widget.hasMore
            ? const CircularProgressIndicator(color: mainColor)
            : const Text('歌詞はここまでです', style: TextStyle(color: Color(0xFF8E8E93))),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (_flying) return;
                setState(() => _drag += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                final velocity = details.velocity.pixelsPerSecond.dx;
                if (_drag > 90 || velocity > 800) {
                  _settle(true);
                } else if (_drag < -90 || velocity < -800) {
                  _settle(false);
                } else {
                  _settle(null);
                }
              },
              onTap: () => widget.onOpen(post),
              child: Transform.translate(
                offset: Offset(_dx, 0),
                child: Transform.rotate(
                  angle: _dx / 1400,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 2, 10),
                    child: SizedBox.expand(
                      child: _LyricCard(
                        post: post,
                        dx: _dx,
                        liked: widget.likedIds.contains(post.id),
                        onOpenUser: () => widget.onOpenUser(post),
                        onPlay: () => widget.onPlay(post),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RoundAction(
                icon: Icons.close,
                color: const Color(0xFF8E8E93),
                onTap: _flying ? null : () => _settle(false),
              ),
              const SizedBox(width: 16),
              _RoundAction(
                icon: Icons.playlist_add_rounded,
                color: mainColor,
                onTap: _flying ? null : () => _onPlaylistTap(post),
              ),
              const SizedBox(width: 16),
              _LikeAction(
                filled: widget.likedIds.contains(post.id),
                celebrate: _celebrate,
                onTap: _flying ? null : () => _settle(true),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _LikeAction extends StatelessWidget {
  const _LikeAction({
    required this.filled,
    required this.celebrate,
    required this.onTap,
  });

  final bool filled;
  final AnimationController celebrate;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: celebrate,
      builder: (context, child) {
        final t = celebrate.value;
        final pop = t > 0 ? 1 + 0.14 * math.sin(t * math.pi) : 1.0;
        final fill = filled ? 1.0 : Curves.easeOutCubic.transform(t);
        final heartFilled = filled || t > 0.25;
        return SizedBox(
          width: 72,
          height: 72,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (t > 0.05 && t < 0.92)
                for (var i = 0; i < 6; i++)
                  Transform.translate(
                    offset: Offset(
                      math.cos(i * math.pi / 3) * (18 + 22 * t),
                      math.sin(i * math.pi / 3) * (18 + 22 * t) - 4 * t,
                    ),
                    child: Opacity(
                      opacity: (1 - t).clamp(0.0, 1.0) * 0.85,
                      child: Icon(
                        i.isEven ? Icons.auto_awesome : Icons.favorite_rounded,
                        size: i.isEven ? 11 : 9,
                        color: i.isEven ? const Color(0xFFFFB8D0) : mainColor,
                      ),
                    ),
                  ),
              Transform.scale(
                scale: pop,
                child: _RoundAction(
                  icon: heartFilled ? Icons.favorite_rounded : Icons.favorite_border,
                  color: Color.lerp(const Color(0xFFC7C7CC), mainColor, fill)!,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LyricCard extends StatelessWidget {
  const _LyricCard({
    required this.post,
    required this.dx,
    required this.liked,
    required this.onOpenUser,
    required this.onPlay,
  });

  final Post post;
  final double dx;
  final bool liked;
  final VoidCallback onOpenUser;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final swipe = (dx.abs() / 160).clamp(0.0, 1.0);
    final genres = post.genres.whereType<String>().where((genre) => genre.isNotEmpty).take(3).toList();
    final scene = swipeCardSceneFor(genres);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.2, sigmaY: 1.2),
              child: Image.asset(scene, fit: BoxFit.cover, alignment: Alignment.center),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xC4000000),
                    Color(0x8A000000),
                    Color(0x33000000),
                  ],
                  stops: [0, 0.62, 1],
                ),
              ),
            ),
            if (swipe > 0)
              ColoredBox(
                color: (dx >= 0 ? const Color(0xFFFF749E) : const Color(0xFF8E8E93)).withValues(alpha: swipe * 0.28),
              ),
            Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Opacity(
                      opacity: dx < 0 ? (-dx / 120).clamp(0, 1) : 0,
                      child: const Text('次へ', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    const Spacer(),
                    Opacity(
                      opacity: dx > 0 ? (dx / 120).clamp(0, 1) : 0,
                      child: const Text('好き', style: TextStyle(color: mainColor, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PostLyricsText.fromPost(post, style: _lyricStyle),
                        const SizedBox(height: 14),
                        Text(
                          post.singName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _titleStyle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          post.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _subStyle,
                        ),
                        if (post.explanation.trim().isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            post.explanation,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: _subStyle,
                          ),
                        ],
                        if (genres.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final genre in genres)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(genre, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFFFFE4EC),
                      backgroundImage: post.userImageUrl.isEmpty || post.userImageUrl == 'null'
                          ? null
                          : NetworkImage(post.userImageUrl),
                      child: post.userImageUrl.isEmpty || post.userImageUrl == 'null'
                          ? const Icon(Icons.person, size: 16, color: mainColor)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: onOpenUser,
                        child: Text(
                          post.userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: Colors.white, shadows: _ink),
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
                              child: Icon(Icons.play_circle_outline_rounded, color: mainColor, size: 28),
                            ),
                          ),
                        );
                      },
                    ),
                    if (liked)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded, color: mainColor, size: 16),
                          const SizedBox(width: 4),
                          Text('いいね済み', style: TextStyle(fontSize: 12, color: mainColor, shadows: _ink)),
                        ],
                      ),
                  ],
                ),
              ],
            ),
            ),
          ],
        ),
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
  fontSize: 17,
  height: 1.45,
  fontWeight: FontWeight.w700,
  color: Colors.white,
  shadows: _ink,
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

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE5E5EA), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
