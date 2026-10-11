import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/common/playlist_picker_sheet.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';

/// タイムラインと同じ [LyricPostCard] 列。
class PostFeedList extends StatelessWidget {
  const PostFeedList({
    super.key,
    required this.posts,
    required this.uid,
    required this.playlists,
    required this.onDeletePost,
    required this.onReportPost,
    this.onBlockUser,
    required this.onAddToPlaylist,
    required this.onCreatePlaylist,
    this.showAuthor = true,
  });

  final List<Post> posts;
  final String? uid;
  final List<dynamic> playlists;
  final Future<void> Function(String postId) onDeletePost;
  final Future<void> Function(String postId) onReportPost;
  final Future<void> Function(String posterId)? onBlockUser;
  final Future<void> Function(String playlistId, Post post) onAddToPlaylist;
  final Future<void> Function(String name) onCreatePlaylist;
  final bool showAuthor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final post in posts)
          LyricPostCard(
            post: post,
            showAuthor: showAuthor,
            onPlaylist: () => _pickPlaylist(context, post),
            menuItems: post.posterId == uid
                ? const [
                    PopupMenuItem(value: 'edit', child: Text('編集する')),
                    PopupMenuItem(value: 'delete', child: Text('削除する')),
                  ]
                : [
                    const PopupMenuItem(value: 'report', child: Text('報告する')),
                    if (onBlockUser != null)
                      const PopupMenuItem(value: 'block', child: Text('ブロックする')),
                  ],
            onMenu: (value) => _onMenu(context, post, value),
          ),
      ],
    );
  }

  Future<void> _pickPlaylist(BuildContext context, Post post) async {
    await showPlaylistPickerSheet(
      context,
      playlists: playlists,
      onSelect: (playlistId) async {
        await onAddToPlaylist(playlistId, post);
      },
      onCreate: (name) async {
        await onCreatePlaylist(name);
      },
    );
  }

  Future<void> _onMenu(BuildContext context, Post post, String value) async {
    if (value == 'delete') {
      final ok = await showAppConfirm(
        context,
        title: '投稿を削除',
        message: 'この投稿を削除しますか？',
        confirm: '削除する',
        destructive: true,
      );
      if (ok) await onDeletePost(post.id);
    } else if (value == 'block' && onBlockUser != null) {
      final ok = await showAppConfirm(
        context,
        title: 'ブロック',
        message: 'このユーザーをブロックしますか？',
        confirm: 'ブロックする',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await onBlockUser!(post.posterId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ブロックしました')));
      }
    } else if (value == 'report') {
      final ok = await showAppConfirm(
        context,
        title: '報告',
        message: 'この投稿を報告しますか？',
        confirm: '報告する',
        destructive: true,
      );
      if (!ok || !context.mounted) return;
      await onReportPost(post.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('報告しました')));
      }
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
  }
}
