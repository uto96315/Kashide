import 'package:flutter/material.dart';
import 'package:str_gram_beta/auth/anonymous_user.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/kashide_theme.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/element/favorite/favorite_button.dart';
import 'package:str_gram_beta/common/open_user_profile.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/common/search_highlight_text.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import 'package:str_gram_beta/share/lyric_share_page.dart';

/// X（Twitter）タイムライン風：左アバター・右本文・アクションは下段で均等タップ領域。
class LyricPostCard extends StatelessWidget {
  const LyricPostCard({
    super.key,
    required this.post,
    required this.menuItems,
    required this.onMenu,
    this.onPlaylist,
    this.onPlay,
    this.isPlaying = false,
    this.showAuthor = true,
    this.showPostTime = true,
    this.highlightQuery,
  });

  final Post post;
  final List<PopupMenuEntry<String>> menuItems;
  final Future<void> Function(String value) onMenu;
  final VoidCallback? onPlaylist;
  final Future<void> Function(Post post)? onPlay;
  final bool isPlaying;
  final bool showAuthor;
  final bool showPostTime;
  final String? highlightQuery;

  static const _cardPadding = EdgeInsets.fromLTRB(16, 12, 16, 8);

  @override
  Widget build(BuildContext context) {
    final image = post.userImageUrl;
    final hasImage = image.isNotEmpty && image != 'null';
    final genres = post.genres.whereType<String>().where((genre) => genre.isNotEmpty);

    final content = _PostCardContent(
      post: post,
      genres: genres,
      menuItems: menuItems,
      onMenu: onMenu,
      onPlaylist: onPlaylist,
      onPlay: onPlay == null ? null : () => onPlay!(post),
      isPlaying: isPlaying,
      showAuthor: showAuthor,
      showPostTime: showPostTime,
      highlightQuery: highlightQuery,
      onOpenUser: () => _openUser(context),
      onOpenPost: (comments) => _openPost(context, comments),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: kashidePostCardBackground(context),
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: showAuthor
          ? Padding(
              padding: _cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _openUser(context),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: hasImage ? NetworkImage(image) : null,
                      child: hasImage
                          ? null
                          : Icon(
                              Icons.person,
                              size: 20,
                              color: kashideSecondaryText(context),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: content),
                ],
              ),
            )
          : Padding(
              padding: _cardPadding,
              child: content,
            ),
    );

  }

  void _openUser(BuildContext context) {
    openUserProfile(
      context,
      posterId: post.posterId,
      userName: publicDisplayName(post.userName),
    );
  }

  void _openPost(BuildContext context, bool comments) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post.id, comments)));
  }

}

class _PostCardContent extends StatelessWidget {
  const _PostCardContent({
    required this.post,
    required this.genres,
    required this.menuItems,
    required this.onMenu,
    required this.onPlaylist,
    required this.onPlay,
    required this.isPlaying,
    required this.showAuthor,
    required this.showPostTime,
    this.highlightQuery,
    required this.onOpenUser,
    required this.onOpenPost,
  });

  final Post post;
  final Iterable<String> genres;
  final List<PopupMenuEntry<String>> menuItems;
  final Future<void> Function(String value) onMenu;
  final VoidCallback? onPlaylist;
  final VoidCallback? onPlay;
  final bool isPlaying;
  final bool showAuthor;
  final bool showPostTime;
  final String? highlightQuery;
  final VoidCallback onOpenUser;
  final void Function(bool comments) onOpenPost;

  @override
  Widget build(BuildContext context) {
    final primary = kashidePrimaryText(context);
    final secondary = kashideSecondaryText(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: showAuthor ? 40 : 32,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (showAuthor) ...[
                      Flexible(
                        child: GestureDetector(
                          onTap: onOpenUser,
                          behavior: HitTestBehavior.opaque,
                          child: Text(
                            publicDisplayName(post.userName),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.2,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                      if (showPostTime)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Text(
                            '·',
                            style: TextStyle(fontSize: 15, height: 1.2, color: secondary),
                          ),
                        ),
                    ],
                    if (showPostTime)
                      Text(
                        post.createdAt,
                        maxLines: 1,
                        style: TextStyle(fontSize: 14, height: 1.2, color: secondary),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                iconSize: 22,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(Icons.more_horiz, color: secondary),
                onSelected: onMenu,
                itemBuilder: (_) => menuItems,
              ),
            ],
          ),
        ),
        if (post.explanation.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            post.explanation,
            style: TextStyle(fontSize: 15, height: 1.4, color: primary),
          ),
        ],
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => onOpenPost(false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: kashidePostLyricsFill(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kashidePostLyricsBorder(context)),
            ),
            child: highlightQuery == null
                ? PostLyricsText.fromPost(
                    post,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  )
                : SearchHighlightText(
                    text: post.text,
                    query: highlightQuery!,
                    textAlign: TextAlign.start,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
          ),
        ),
        if (genres.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final genre in genres)
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(genre, 'genre')));
                  },
                  child: highlightQuery == null
                      ? Text(
                          '#$genre',
                          style: const TextStyle(
                            fontSize: 14,
                            color: mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : SearchHighlightText(
                          text: '#$genre',
                          query: highlightQuery!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: mainColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(post.singName, 'singName')));
                },
                child: highlightQuery == null
                    ? Text(
                        post.singName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      )
                    : SearchHighlightText(
                        text: post.singName,
                        query: highlightQuery!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primary,
                        ),
                      ),
              ),
            ),
            Text(' · ', style: TextStyle(fontSize: 14, color: secondary)),
            Flexible(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(post.artist, 'artist')));
                },
                child: highlightQuery == null
                    ? Text(
                        post.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: secondary),
                      )
                    : SearchHighlightText(
                        text: post.artist,
                        query: highlightQuery!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: secondary),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: ListenUrlPlaySlot(
                storedUrl: post.youtubeLink,
                artist: post.artist,
                singName: post.singName,
                builder: (context, listenUrl) {
                  if (listenUrl == null || listenUrl.isEmpty || onPlay == null) {
                    return const _TimelineActionPlaceholder();
                  }
                  return _TimelineAction(
                    icon: isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline_rounded,
                    iconColor: mainColor,
                    onTap: onPlay!,
                  );
                },
              ),
            ),
            Expanded(
              child: _TimelineAction(
                icon: Icons.chat_bubble_outline_rounded,
                count: post.commentCount,
                onTap: () => onOpenPost(true),
              ),
            ),
            Expanded(
              child: Center(
                child: FavoriteButton(post.id, post.likedCount, compact: true),
              ),
            ),
            Expanded(
              child: onPlaylist != null
                  ? _TimelineAction(
                      icon: Icons.playlist_add_rounded,
                      onTap: onPlaylist!,
                    )
                  : const _TimelineActionPlaceholder(),
            ),
            Expanded(
              child: _TimelineAction(
                icon: Icons.ios_share_rounded,
                onTap: () => openLyricShare(
                  context,
                  LyricShareData(
                    lyrics: post.text,
                    title: post.singName,
                    artist: post.artist,
                    genres: post.genres.whereType<String>().toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

/// アクション列の幅を揃えるための空スロット。
class _TimelineActionPlaceholder extends StatelessWidget {
  const _TimelineActionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 42);
  }
}

class _TimelineAction extends StatelessWidget {
  const _TimelineAction({
    required this.icon,
    this.count,
    this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final int? count;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: iconColor ?? kashideSecondaryText(context)),
              if (count != null) ...[
                const SizedBox(width: 6),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 14,
                    color: iconColor ?? kashideSecondaryText(context),
                    fontWeight: FontWeight.w500,
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
