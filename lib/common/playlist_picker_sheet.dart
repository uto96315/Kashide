import 'package:flutter/material.dart';

Future<void> showPlaylistPickerSheet(
  BuildContext context, {
  required List<dynamic> playlists,
  required Future<void> Function(String playlistId) onSelect,
  required Future<void> Function(String name) onCreate,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('プレイリストに追加', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (playlists.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('プレイリストがありません', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8E93))),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: playlists.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE5E5EA)),
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final name = playlist['playlistName'] as String? ?? '';
                      final id = playlist['id'] as String? ?? '';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.queue_music, color: Color(0xFF1C1C1E)),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF8E8E93)),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          await onSelect(id);
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1C1C1E),
                  side: const BorderSide(color: Color(0xFFE5E5EA)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  final name = await _askNewPlaylistName(context);
                  if (name != null && name.isNotEmpty) {
                    await onCreate(name);
                  }
                },
                child: const Text('新しいプレイリストを作る', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _askNewPlaylistName(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => const _NewPlaylistNameDialog(),
  );
}

class _NewPlaylistNameDialog extends StatefulWidget {
  const _NewPlaylistNameDialog();

  @override
  State<_NewPlaylistNameDialog> createState() => _NewPlaylistNameDialogState();
}

class _NewPlaylistNameDialogState extends State<_NewPlaylistNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('プレイリスト名', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'お気に入りの曲',
                filled: true,
                fillColor: const Color(0xFFF2F2F7),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onSubmitted: (value) => Navigator.pop(context, value.trim()),
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
                    onPressed: () => Navigator.pop(context, _controller.text.trim()),
                    child: const Text('作る', style: TextStyle(color: Color(0xFF1C1C1E), fontWeight: FontWeight.w700)),
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
