import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/playlistDetails/playlist_details_page.dart';
import 'package:str_gram_beta/providers.dart';

class PlaylistPage extends ConsumerWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(playlistProvider);
    return Scaffold(
      body: Column(
        children: [
          const ScreenTop(showBack: false),
          Expanded(
            child: !model.ready
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : model.playlists.isEmpty
                    ? const EmptyState(icon: Icons.queue_music, message: 'プレイリストはまだありません')
                    : RefreshIndicator(
                        color: mainColor,
                        onRefresh: model.getPlaylists,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: model.playlists.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final playlist = model.playlists[index];
                            return Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PlaylistDetailsPage(playlist['id'], playlist['playlistName']),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: const Color(0xFFFFD6E4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.queue_music, color: mainColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          playlist['playlistName'],
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          final ok = await showAppConfirm(
                                            context,
                                            title: 'プレイリストを削除',
                                            message: '「${playlist['playlistName']}」を削除しますか？',
                                            confirm: '削除する',
                                            destructive: true,
                                          );
                                          if (ok) await model.deletePlaylist(playlist['id']);
                                        },
                                        icon: const Icon(Icons.delete_outline, color: Color(0xFF8E8E93)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: PrimaryButton(
            label: 'プレイリストを作る',
            onPressed: () => _create(context, model),
          ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, dynamic model) async {
    final trimmed = await showDialog<String>(
      context: context,
      builder: (context) => const _CreatePlaylistDialog(),
    );
    if (trimmed == null || trimmed.isEmpty) return;
    model.addPlaylistController.text = trimmed;
    model.setNewName(trimmed);
    await model.addNewPlaylist();
    await model.getPlaylists();
    model.addPlaylistController.text = '';
  }
}

class _CreatePlaylistDialog extends StatefulWidget {
  const _CreatePlaylistDialog();

  @override
  State<_CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<_CreatePlaylistDialog> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.pop(context, _name.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('プレイリストを作る', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'お気に入りの曲',
                filled: true,
                fillColor: const Color(0xFFFFF7F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('キャンセル', style: TextStyle(color: Color(0xFF8E8E93))),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: _submit,
                    child: const Text('作る', style: TextStyle(color: mainColor, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
