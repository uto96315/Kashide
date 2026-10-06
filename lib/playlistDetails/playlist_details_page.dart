import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/screen_top.dart';
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
                    ? const EmptyState(icon: Icons.queue_music, message: 'まだ曲が入っていません')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: model.playlistSongs.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFFFE4EC)),
                        itemBuilder: (context, index) {
                          final song = model.playlistSongs[index];
                          final stored = (song['youtubeUrl'] as String?) ?? '';
                          final url = stored.isNotEmpty
                              ? stored
                              : 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('${song['artist']} ${song['singName']}')}';
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${song['singName']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                    Text('${song['artist']}', style: const TextStyle(color: Color(0xFF8E8E93))),
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
