import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/song/song_pick_page.dart';
import 'package:str_gram_beta/song/song_quote.dart';

class PostPage extends ConsumerWidget {
  const PostPage(this.defaultGenre, {super.key});
  final String? defaultGenre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(postProvider(defaultGenre));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Column(
          children: [
            const ScreenTop(),
            Expanded(
              child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              '曲と歌詞',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F1419)),
            ),
            const SizedBox(height: 4),
            const Text(
              '必須 · タップして曲と載せる歌詞を選ぶ',
              style: TextStyle(fontSize: 13, color: Color(0xFF536471)),
            ),
            const SizedBox(height: 10),
            _SongCard(
              artist: model.singerName,
              title: model.singName,
              artworkUrl: model.artworkUrl,
              lyrics: model.lyrics,
              onPick: () async {
                final quote = await Navigator.push<SongQuote>(
                  context,
                  MaterialPageRoute(builder: (_) => const SongPickPage()),
                );
                if (quote != null) model.applyQuote(quote);
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: model.explanationController,
              maxLines: 4,
              maxLength: PostModelLimit.explanation,
              decoration: const InputDecoration(
                labelText: 'この曲への思い（任意）',
                alignLabelWithHint: true,
              ),
              onChanged: model.setExplanation,
            ),
            const SizedBox(height: 8),
            const Text('ジャンル（最大3つ）', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            Wrap(
              runSpacing: 10,
              spacing: 8,
              children: [
                for (final genre in model.defaultGenresList)
                  FilterChip(
                    label: Text(genre),
                    selected: model.genres.contains(genre),
                    onSelected: (_) {
                      if (model.genres.contains(genre)) {
                        model.deleteGenre(genre);
                      } else {
                        model.setGenre(genre);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: model.genreController,
                    maxLength: 15,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'ジャンルを入力して追加',
                      counterText: '',
                      filled: true,
                      fillColor: const Color(0xFFFFF7F8),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (text) {
                      model.addGenre(text);
                      model.genreController.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    model.addGenre(model.genreController.text);
                    model.genreController.clear();
                  },
                  child: const Text('追加', style: TextStyle(color: mainColor, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
              ),
            ],
          ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
              label: '投稿する',
              loading: model.posting,
              onPressed: model.posting
                  ? null
                  : () async {
                      final message = model.validationMessage();
                      if (message != null) {
                        await showAppMessage(context, message);
                        return;
                      }
                      try {
                        await model.post();
                        if (!context.mounted) return;
                        await ref.read(timelineProvider).getFirstPostData();
                        ref.invalidate(myPageProvider);
                        if (!context.mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(context);
                        messenger.showSnackBar(const SnackBar(content: Text('投稿しました')));
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }
}

class PostModelLimit {
  static const explanation = 300;
}

class _SongCard extends StatelessWidget {
  const _SongCard({
    required this.onPick,
    this.artist,
    this.title,
    this.artworkUrl,
    this.lyrics,
  });

  final VoidCallback onPick;
  final String? artist;
  final String? title;
  final String? artworkUrl;
  final String? lyrics;

  @override
  Widget build(BuildContext context) {
    final hasSong = (artist ?? '').isNotEmpty && (title ?? '').isNotEmpty;
    final emptyStyle = !hasSong;
    return Material(
      color: emptyStyle ? const Color(0xFFFFF0F5) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(emptyStyle ? 18 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emptyStyle ? mainColor : const Color(0xFFFFD0E0),
              width: emptyStyle ? 2 : 1,
            ),
            boxShadow: emptyStyle
                ? [
                    BoxShadow(
                      color: mainColor.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: hasSong
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Art(url: artworkUrl),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(artist!, style: const TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ),
                        const Text('変更', style: TextStyle(color: mainColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (lyrics ?? '').isEmpty ? '歌詞の範囲を選んでください' : lyrics!,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(lyrics ?? '').length} / 300',
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: mainColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.library_music_rounded, color: mainColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '曲を選んで、載せたい歌詞の範囲を指定する',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                          color: Color(0xFF0F1419),
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: mainColor, size: 28),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: url == null
          ? Container(
              width: 48,
              height: 48,
              color: const Color(0xFFFFE4EC),
              child: const Icon(Icons.music_note, color: mainColor),
            )
          : Image.network(url!, width: 48, height: 48, fit: BoxFit.cover),
    );
  }
}
