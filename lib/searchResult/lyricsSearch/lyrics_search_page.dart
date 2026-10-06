import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/genre_browse_header.dart';
import 'package:str_gram_beta/common/post_feed_list.dart';
import 'package:str_gram_beta/providers.dart';

class LyricsSearchPage extends ConsumerWidget {
  const LyricsSearchPage(this.searchWord, {super.key});
  final String searchWord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(lyricsSearchProvider(searchWord));
    final timeline = ref.watch(timelineProvider);

    if (model.isLoading) {
      return const Center(child: CircularProgressIndicator(color: mainColor));
    }

    if (model.lyricsResultCount == 0) {
      return const EmptyState(message: '最近の投稿には見つかりませんでした');
    }

    return ColoredBox(
      color: Colors.white,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: QueryResultHeader(
              title: '歌詞「$searchWord」',
              subtitle: '最近の投稿から${model.lyricsResultCount}件',
            ),
          ),
          SliverToBoxAdapter(
            child: PostFeedList(
              posts: model.lyricsResultList,
              uid: timeline.uid,
              playlists: timeline.playList,
              onDeletePost: (id) async {
                await timeline.deletePosts(id);
                ref.invalidate(lyricsSearchProvider(searchWord));
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
