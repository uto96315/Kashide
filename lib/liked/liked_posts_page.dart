import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/post_feed_list.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';

class LikedPostsPage extends ConsumerWidget {
  const LikedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(likedPostsProvider);
    final playlists = ref.watch(playlistProvider).playlists;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const ScreenTop(title: 'いいねした歌詞'),
          Expanded(
            child: model.loading
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : model.posts.isEmpty
                    ? const EmptyState(icon: Icons.favorite_border, message: 'まだいいねした歌詞がありません')
                    : ListView(
                        children: [
                          PostFeedList(
                            posts: model.posts,
                            uid: uid,
                            playlists: playlists,
                            onDeletePost: (id) async {
                              final timeline = ref.read(timelineProvider);
                              await timeline.deletePosts(id);
                              ref.invalidate(likedPostsProvider);
                              await ref.read(myPageProvider).loadLikedCount();
                            },
                            onReportPost: (id) => ref.read(timelineProvider).reportPosts(id),
                            onAddToPlaylist: (playlistId, post) => ref.read(timelineProvider).addToPlaylist(
                              playlistId,
                              post.artist,
                              post.singName,
                              post.youtubeLink,
                              post.id,
                            ),
                            onCreatePlaylist: (name) async {
                              final timeline = ref.read(timelineProvider);
                              timeline.addPlaylistController.text = name;
                              timeline.setNewName(name);
                              await timeline.addNewPlaylist();
                              await ref.read(playlistProvider).getPlaylists();
                              timeline.addPlaylistController.text = '';
                            },
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
