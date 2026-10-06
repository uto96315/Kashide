import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/genre_browse_header.dart';
import 'package:str_gram_beta/common/post_feed_list.dart';
import 'package:str_gram_beta/providers.dart';

class GenreSearchPage extends ConsumerWidget {
  const GenreSearchPage(this.searchWord, {super.key});
  final String searchWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(genreSearchProvider(searchWord));
    final timeline = ref.watch(timelineProvider);

    if (!model.ready) {
      return const Center(child: CircularProgressIndicator(color: mainColor));
    }
    if (model.genreResultCount == 0) {
      return const EmptyState(message: '投稿が見つかりませんでした');
    }

    return ColoredBox(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: GenreBrowseHeader(
              genre: searchWord,
              postCount: model.genreResultCount,
            ),
          ),
          SliverToBoxAdapter(
            child: PostFeedList(
              posts: model.genreResultList,
              uid: timeline.uid,
              playlists: timeline.playList,
              onDeletePost: (id) async {
                await timeline.deletePosts(id);
                ref.invalidate(genreSearchProvider(searchWord));
              },
              onReportPost: timeline.reportPosts,
              onAddToPlaylist: (playlistId, post) => timeline.addToPlaylist(
                playlistId,
                post.artist,
                post.singName,
                post.youtubeLink,
                post.id,
              ),
              onCreatePlaylist: (name) async {
                timeline.addPlaylistController.text = name;
                timeline.setNewName(name);
                await timeline.addNewPlaylist();
                await timeline.getPlayListData();
                timeline.addPlaylistController.text = '';
              },
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
