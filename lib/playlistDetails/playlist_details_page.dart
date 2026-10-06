import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import 'package:str_gram_beta/providers.dart';

class PlaylistDetailsPage extends ConsumerWidget {
  const PlaylistDetailsPage(this.playlistId, this.playlistName, {super.key});
  final String playlistId;
  final String playlistName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(playlistDetailsProvider(playlistId));
    return Scaffold(
      body: Column(
        children: [
          ScreenTop(title: playlistName),
          Expanded(
            child: !model.ready
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : model.playlistSongs.isEmpty
                    ? EmptyState(
                        icon: Icons.queue_music,
                        message: 'まだ曲が入っていません',
                        detail: 'ホームの歌詞カードでプレイリストボタンを押し、「$playlistName」を選んで追加できます。',
                        actionLabel: 'ホームで探す',
                        onAction: () {
                          ref.read(homeTabIndexProvider.notifier).setTab(0);
                          Navigator.of(context).pop();
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: model.playlistSongs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFFFE4EC)),
                        itemBuilder: (context, index) {
                          final song = model.playlistSongs[index];
                          final postId = song['postId'] as String?;
                          final lyric = (song['lyricText'] as String?)?.trim() ?? '';
                          final stored = (song['youtubeUrl'] as String?) ?? '';
                          final url = stored.isNotEmpty
                              ? stored
                              : 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${song['artist']} ${song['singName']}')}';
                          return InkWell(
                            onTap: postId != null && postId.isNotEmpty
                                ? () => Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => PostDetailPage(postId, false)),
                                    )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${song['singName']}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                        ),
                                        Text(
                                          '${song['artist']}',
                                          style: const TextStyle(color: Color(0xFF8E8E93)),
                                        ),
                                        if (lyric.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            lyric,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF3C3C43)),
                                          ),
                                        ],
                                        if (postId != null && postId.isNotEmpty)
                                          const Padding(
                                            padding: EdgeInsets.only(top: 6),
                                            child: Text(
                                              'タップで歌詞投稿を開く',
                                              style: TextStyle(fontSize: 12, color: mainColor, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.play_circle, color: mainColor, size: 30),
                                    onPressed: () => model.launchURL(url),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Color(0xFF8E8E93)),
                                    onPressed: () async {
                                      final ok = await showAppConfirm(
                                        context,
                                        title: '曲を外す',
                                        message: '「${song['singName']}」をこのプレイリストから外しますか？',
                                        confirm: '外す',
                                        destructive: true,
                                      );
                                      if (ok) await model.deleteFromPlaylist(song['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
