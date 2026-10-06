import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/genre_browse_header.dart';
import 'package:str_gram_beta/common/post_feed_list.dart';
import 'package:str_gram_beta/providers.dart';

class SingSearchPage extends ConsumerWidget {
  const SingSearchPage(this.searchWord, {super.key});
  final String searchWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(singSearchProvider(searchWord));
    final timeline = ref.watch(timelineProvider);

    if (!model.ready) {
      return const Center(child: CircularProgressIndicator(color: mainColor));
    }
    if (model.singResultCount == 0) {
      return const EmptyState(message: '投稿が見つかりませんでした');
    }

    return ColoredBox(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: QueryResultHeader(
              title: '曲名「$searchWord」',
              subtitle: '${model.singResultCount}件の投稿',
            ),
          ),
          SliverToBoxAdapter(
            child: PostFeedList(
              posts: model.singResultList,
              uid: timeline.uid,
              playlists: timeline.playList,
              onDeletePost: (id) async {
                await timeline.deletePosts(id);
                ref.invalidate(singSearchProvider(searchWord));
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
