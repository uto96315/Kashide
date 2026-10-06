

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/genre_empty_message.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/common/playlist_picker_sheet.dart';
import 'package:str_gram_beta/common/post_fab.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';
import 'package:str_gram_beta/genre/genre_model.dart';
import 'package:str_gram_beta/post/post_page.dart';
import 'package:str_gram_beta/providers.dart';

class GenrePage extends ConsumerWidget {
  const GenrePage(this.genre, this.condition, {this.title, super.key});
  final String genre;
  final String condition;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(genreProvider((genre: genre, condition: condition)));
    final isPoster = condition == 'poster';
    final pageTitle = title ?? (condition == 'genre' ? '「$genre」' : genre);
    final topTitle = isPoster ? 'プロフィール' : pageTitle;

    return Scaffold(
      backgroundColor: isPoster ? const Color(0xFFF2F2F7) : Colors.white,
      body: Column(
        children: [
          ScreenTop(title: topTitle),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isPoster) _PosterProfileHeader(model: model, fallbackName: pageTitle),
                  if (model.postCount == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator(color: mainColor)),
                    )
                  else if (model.postCount == 0)
                    EmptyState(message: genreEmptyMessage(condition))
                  else ...[
                    if (!isPoster) ...[
                      const SizedBox(height: 16),
                      Text(
                        '全部で${model.postCount}件の投稿が見つかりました。',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF536471)),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('投稿', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3C))),
                        ),
                      ),
                    ],
                    for (final post in model.genrePostsList)
                      LyricPostCard(
                        post: post,
                        showAuthor: !isPoster,
                        onPlaylist: () => _pickPlaylist(context, model, post),
                        menuItems: post.posterId == model.uid
                            ? const [
                                PopupMenuItem(value: 'edit', child: Text('編集する')),
                                PopupMenuItem(value: 'delete', child: Text('削除する')),
                              ]
                            : const [
                                PopupMenuItem(value: 'report', child: Text('報告する')),
                              ],
                        onMenu: (value) => _onPostMenu(context, model, post, value),
                      ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: condition == 'genre'
          ? PostFab(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PostPage(genre)));
              },
            )
          : null,
    );
  }

  Future<void> _pickPlaylist(BuildContext context, GenreModel model, dynamic post) async {
    await showPlaylistPickerSheet(
      context,
      playlists: model.playList,
      onSelect: (playlistId) async {
        await model.addToPlaylist(playlistId, post.artist, post.singName, post.youtubeLink, post.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('プレイリストに追加しました')));
        }
      },
      onCreate: (name) async {
        model.addPlaylistController.text = name;
        model.setNewName(name);
        await model.addNewPlaylist();
        await model.getPlayListData();
        model.addPlaylistController.text = '';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('プレイリストを作成しました')));
        }
      },
    );
  }

  Future<void> _onPostMenu(BuildContext context, GenreModel model, dynamic post, String value) async {
    if (value == 'delete') {
      final ok = await showAppConfirm(
        context,
        title: '投稿を削除',
        message: 'この投稿を削除しますか？',
        confirm: '削除する',
        destructive: true,
      );
      if (ok) await model.deletePosts(post.id);
    } else if (value == 'report') {
      await model.reportPosts(post.id);
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

class _PosterProfileHeader extends StatelessWidget {
  const _PosterProfileHeader({required this.model, required this.fallbackName});

  final GenreModel model;
  final String fallbackName;

  @override
  Widget build(BuildContext context) {
    final image = model.displayProfileImageUrl;
    final hasImage = image != null && image.isNotEmpty;
    final name = model.profileUserName ?? fallbackName;
    final intro = model.profileIntroduction?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFE5E5EA),
            backgroundImage: hasImage ? NetworkImage(image) : null,
            child: hasImage ? null : const Icon(Icons.person, size: 44, color: Color(0xFF8E8E93)),
          ),
          const SizedBox(height: 12),
          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF0F0F0F))),
          if (intro.isNotEmpty && intro != '未設定') ...[
            const SizedBox(height: 8),
            Text(
              intro,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF3A3A3C)),
            ),
          ],
          if (model.postCount != null) ...[
            const SizedBox(height: 10),
            Text(
              '${model.postCount}件の投稿',
              style: const TextStyle(fontSize: 14, color: Color(0xFF536471)),
            ),
          ],
        ],
      ),
    );
  }
}
