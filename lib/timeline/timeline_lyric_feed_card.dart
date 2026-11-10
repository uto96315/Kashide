import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/auth/anonymous_user.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/common/open_user_profile.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/common/swipe_card_scene.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import 'package:str_gram_beta/providers.dart';

/// タイムライン一覧：モック準拠のシネマティック歌詞カード（タップでひとことを展開）。
class TimelineLyricFeedCard extends ConsumerStatefulWidget {
  const TimelineLyricFeedCard({
    super.key,
    required this.post,
    required this.menuItems,
    required this.onMenu,
    this.onPlaylist,
    this.onPlay,
    this.isPlaying = false,
  });

  final Post post;
  final List<PopupMenuEntry<String>> menuItems;
  final Future<void> Function(String value) onMenu;
  final VoidCallback? onPlaylist;
  final Future<void> Function(Post post)? onPlay;
  final bool isPlaying;

  @override
  ConsumerState<TimelineLyricFeedCard> createState() =>
      _TimelineLyricFeedCardState();
}

class _TimelineLyricFeedCardState extends ConsumerState<TimelineLyricFeedCard> {
  var _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  void _openComments() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(widget.post.id, true),
      ),
    );
  }

  void _openDetail() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PostDetailPage(widget.post.id, false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final scene = swipeCardSceneFor(
      post.genres.whereType<String>().where((g) => g.isNotEmpty),
    );
    final hasExplanation = post.explanation.trim().isNotEmpty;
    final minHeight = _expanded ? 300.0 : 212.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: minHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                    Image.asset(scene, fit: BoxFit.cover),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.55),
                            Colors.black.withValues(alpha: 0.25),
                            Colors.black.withValues(alpha: 0.5),
                            Colors.black.withValues(alpha: 0.82),
                          ],
                          stops: const [0, 0.35, 0.72, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 4,
                      child: PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.more_horiz_rounded,
                          color: Colors.white,
                        ),
                        color: const Color(0xFF2C2C2E),
                        onSelected: widget.onMenu,
                        itemBuilder: (_) => widget.menuItems,
                      ),
                    ),
                    Positioned(
                      left: 14,
                      right: 14,
                      top: 36,
                      bottom: 76,
                      child: GestureDetector(
                        onTap: _toggleExpanded,
                        behavior: HitTestBehavior.opaque,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                physics: _expanded
                                    ? const BouncingScrollPhysics()
                                    : const NeverScrollableScrollPhysics(),
                                child: _LyricQuote(post: post),
                              ),
                            ),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 220),
                              crossFadeState: _expanded
                                  ? CrossFadeState.showSecond
                                  : CrossFadeState.showFirst,
                              firstChild: const SizedBox.shrink(),
                              secondChild: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: _ExpandedBody(
                                  post: post,
                                  hasExplanation: hasExplanation,
                                  onOpenUser: () => openUserProfile(
                                    context,
                                    posterId: post.posterId,
                                    userName: post.userName,
                                  ),
                                  onOpenDetail: _openDetail,
                                ),
                              ),
                            ),
                            if (!_expanded && hasExplanation)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  'タップでひとことを表示',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: _CardFooter(
                        post: post,
                        isPlaying: widget.isPlaying,
                        onPlay: widget.onPlay == null
                            ? null
                            : () => widget.onPlay!(post),
                        onComment: _openComments,
                        onPlaylist: widget.onPlaylist,
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LyricQuote extends StatelessWidget {
  const _LyricQuote({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 4,
            margin: const EdgeInsets.only(right: 12, top: 2, bottom: 2),
            decoration: BoxDecoration(
              color: mainColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: PostLyricsText.fromPost(
              post,
              maxLines: 6,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                fontSize: 17,
                height: 1.65,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [
                  Shadow(blurRadius: 8, color: Color(0x99000000)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.post,
    required this.hasExplanation,
    required this.onOpenUser,
    required this.onOpenDetail,
  });

  final Post post;
  final bool hasExplanation;
  final VoidCallback onOpenUser;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final image = post.userImageUrl;
    final hasImage = image.isNotEmpty && image != 'null';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onOpenUser,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFFFE4EC),
                    backgroundImage: hasImage ? NetworkImage(image) : null,
                    child: hasImage
                        ? null
                        : const Icon(Icons.person, size: 16, color: mainColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      publicDisplayName(post.userName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasExplanation
                  ? post.explanation.trim()
                  : 'ひとことはまだありません',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: Colors.white.withValues(alpha: hasExplanation ? 0.95 : 0.65),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenDetail,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('投稿を開く', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFooter extends ConsumerWidget {
  const _CardFooter({
    required this.post,
    required this.isPlaying,
    required this.onComment,
    this.onPlay,
    this.onPlaylist,
  });

  final Post post;
  final bool isPlaying;
  final VoidCallback onComment;
  final VoidCallback? onPlay;
  final VoidCallback? onPlaylist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0),
            Colors.black.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        child: Row(
          children: [
            _ArtworkChip(artist: post.artist, title: post.singName),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    post.singName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    post.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            _FooterIcon(
              onTap: onComment,
              icon: Icons.chat_bubble_outline_rounded,
              label: post.commentCount > 0 ? '${post.commentCount}' : null,
            ),
            const SizedBox(width: 4),
            _OverlayFavorite(postId: post.id, likedCount: post.likedCount),
            const SizedBox(width: 2),
            ListenUrlPlaySlot(
              storedUrl: post.youtubeLink,
              artist: post.artist,
              singName: post.singName,
              builder: (context, url) {
                if (url == null || url.isEmpty || onPlay == null) {
                  return const SizedBox(width: 44, height: 44);
                }
                return Material(
                  color: mainColor,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onPlay,
                    customBorder: const CircleBorder(),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterIcon extends StatelessWidget {
  const _FooterIcon({
    required this.onTap,
    required this.icon,
    this.label,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              if (label != null) ...[
                const SizedBox(width: 4),
                Text(
                  label!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlayFavorite extends ConsumerWidget {
  const _OverlayFavorite({required this.postId, required this.likedCount});

  final String postId;
  final int likedCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(favoriteProvider(FavoriteArgs(postId, likedCount)));
    final liked = model.isLiked;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await model.doLike(postId, likedCount);
          await model.checkLiked();
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: liked ? mainColor : Colors.white,
                size: 22,
              ),
              if ((model.likedCount ?? 0) > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '${model.likedCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtworkChip extends ConsumerStatefulWidget {
  const _ArtworkChip({required this.artist, required this.title});

  final String artist;
  final String title;

  @override
  ConsumerState<_ArtworkChip> createState() => _ArtworkChipState();
}

class _ArtworkChipState extends ConsumerState<_ArtworkChip> {
  String? _url;
  var _requested = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (_requested) return;
    _requested = true;
    final url = await ref.read(songSearchServiceProvider).lookupArtworkUrl(
          artist: widget.artist,
          title: widget.title,
        );
    if (mounted && url != null) setState(() => _url = url);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 44,
        height: 44,
        child: _url != null
            ? Image.network(_url!, fit: BoxFit.cover)
            : ColoredBox(
                color: Colors.white.withValues(alpha: 0.15),
                child: const Icon(Icons.music_note_rounded, color: Colors.white70),
              ),
      ),
    );
  }
}
