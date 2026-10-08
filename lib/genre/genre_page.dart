

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/genre_browse_header.dart';
import 'package:str_gram_beta/common/genre_empty_message.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/post_feed_list.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/genre/genre_model.dart';
import 'package:str_gram_beta/common/block_user_actions.dart';
import 'package:str_gram_beta/post/post_validation.dart';
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
    final isGenre = condition == 'genre';
    final pageTitle = title ?? (isGenre ? genre : genre);
    final navTitle = isPoster ? 'プロフィール' : (isGenre ? '' : pageTitle);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          ScreenTop(title: navTitle.isEmpty ? null : navTitle),
          Expanded(
            child: _GenreBody(
              model: model,
              genre: genre,
              condition: condition,
              isPoster: isPoster,
              isGenre: isGenre,
              pageTitle: pageTitle,
            ),
          ),
        ],
      ),
    );
  }
}

class _GenreBody extends ConsumerWidget {
  const _GenreBody({
    required this.model,
    required this.genre,
    required this.condition,
    required this.isPoster,
    required this.isGenre,
    required this.pageTitle,
  });

  final GenreModel model;
  final String genre;
  final String condition;
  final bool isPoster;
  final bool isGenre;
  final String pageTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isPoster && ref.watch(blockListProvider).isBlocked(genre)) {
      return const EmptyState(
        icon: Icons.block,
        message: 'ブロック中のユーザーです',
        detail: 'マイページのメニュー → ブロック中のユーザー から解除できます。',
      );
    }
    final posts = withoutBlockedPosts(model.genrePostsList, ref.watch(blockListProvider).blockedIds);
    if (model.postCount == null) {
      return const Center(child: CircularProgressIndicator(color: mainColor));
    }
    if (model.postCount == 0) {
      return EmptyState(message: genreEmptyMessage(condition));
    }

    return RefreshIndicator(
      color: mainColor,
      onRefresh: () => model.getGenrePosts(genre),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isPoster) _PosterProfileHeader(model: model, fallbackName: pageTitle),
                if (isGenre)
                  GenreBrowseHeader(genre: genre, postCount: model.postCount!)
                else if (!isPoster)
                  QueryResultHeader(
                    title: pageTitle,
                    subtitle: '${model.postCount}件の投稿',
                  )
                else ...[
                  const SizedBox(height: 4),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('投稿', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3C))),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: PostFeedList(
              posts: posts,
              uid: model.uid,
              playlists: model.playList,
              showAuthor: !isPoster,
              onAfterDetailVisit: model.refreshViewCountForPost,
              trackFeedView: true,
              onDeletePost: model.deletePosts,
              onReportPost: model.reportPosts,
              onBlockUser: (posterId) => blockUserFromFeed(context, ref, posterId),
              onAddToPlaylist: (playlistId, post) => model.addToPlaylist(
                playlistId,
                post.artist,
                post.singName,
                post.youtubeLink,
                post.id,
              ),
              onCreatePlaylist: (name) async {
                model.addPlaylistController.text = name;
                model.setNewName(name);
                await model.addNewPlaylist();
                await model.getPlayListData();
                model.addPlaylistController.text = '';
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
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
