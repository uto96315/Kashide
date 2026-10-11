import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/song/song_pick_page.dart';
import 'package:str_gram_beta/song/song_quote.dart';
import 'package:str_gram_beta/post/post_model.dart';

class PostPage extends ConsumerStatefulWidget {
  const PostPage(
    this.defaultGenre, {
    super.key,
    this.analyticsSource = 'unknown',
  });

  final String? defaultGenre;
  final String analyticsSource;

  @override
  ConsumerState<PostPage> createState() => _PostPageState();
}

class _PostPageState extends ConsumerState<PostPage> {
  var _loggedComposeOpen = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loggedComposeOpen) return;
    _loggedComposeOpen = true;
    ref
        .read(appAnalyticsProvider)
        .logPostComposeOpen(source: widget.analyticsSource);
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(postProvider(widget.defaultGenre));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7FA),
        body: Column(
          children: [
            ScreenTop(
              title: '投稿',
              trailing: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton(
                  onPressed: model.posting ? null : () => _submit(model),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 36),
                    maximumSize: const Size(108, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    backgroundColor: mainColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: mainColor.withValues(alpha: 0.55),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: model.posting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('投稿する'),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                children: [
                  Row(
                    children: [
                      const Text(
                        '曲と歌詞',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: Color(0xFF202027),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE7EF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '必須',
                          style: TextStyle(
                            color: Color(0xFFDB4E7F),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    '曲を選んで、投稿したい歌詞を指定します',
                    style: TextStyle(fontSize: 13, color: Color(0xFF777780)),
                  ),
                  const SizedBox(height: 14),
                  _SongCard(
                    artist: model.singerName,
                    title: model.singName,
                    artworkUrl: model.artworkUrl,
                    lyricSegments: model.lyricSegments,
                    lyrics: model.lyrics,
                    onPick: () async {
                      final quote = await Navigator.push<SongQuote>(
                        context,
                        MaterialPageRoute(builder: (_) => const SongPickPage()),
                      );
                      if (quote != null) model.applyQuote(quote);
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: model.explanationController,
                    minLines: 2,
                    maxLines: 3,
                    maxLength: PostModelLimit.explanation,
                    cursorColor: const Color(0xFFC58C9E),
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.45,
                      color: Color(0xFF343139),
                    ),
                    decoration: const InputDecoration(
                      labelText: '曲へのコメント（任意）',
                      hintText: '心に残った歌詞や曲のこと',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFB2ADB4),
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF89777F),
                      ),
                      alignLabelWithHint: true,
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.fromLTRB(16, 17, 16, 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(color: Color(0xFFE5E3E8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(16)),
                        borderSide: BorderSide(
                          color: Color(0xFFD8B5C1),
                          width: 1.2,
                        ),
                      ),
                    ),
                    onChanged: model.setExplanation,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ジャンル',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202027),
                          ),
                        ),
                      ),
                      Text(
                        '${model.genres.length}/3',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF536471),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    runSpacing: 4,
                    spacing: 4,
                    children: [
                      for (final genre in model.defaultGenresList)
                        Builder(
                          builder: (context) {
                            final selected = model.genres.contains(genre);
                            return FilterChip(
                              visualDensity: VisualDensity.compact,
                              labelPadding: const EdgeInsets.symmetric(
                                horizontal: 5,
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              label: Text(
                                genre,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? const Color(0xFF79515F)
                                      : const Color(0xFF5F5D64),
                                ),
                              ),
                              selected: selected,
                              showCheckmark: false,
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFFFFEEF3),
                              side: BorderSide(
                                color: selected
                                    ? const Color(0xFFE4BFCA)
                                    : const Color(0xFFE8E4E8),
                              ),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                                vertical: 5,
                              ),
                              onSelected: (_) {
                                if (selected) {
                                  model.deleteGenre(genre);
                                } else {
                                  model.setGenre(genre);
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: model.genreController,
                          maxLength: 15,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'ジャンルを追加',
                            counterText: '',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: Color(0xFFE5E3E8),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: mainColor,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: (text) {
                            model.addGenre(text);
                            model.genreController.clear();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          model.addGenre(model.genreController.text);
                          model.genreController.clear();
                        },
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('追加'),
                        style: FilledButton.styleFrom(
                          foregroundColor: const Color(0xFFCC4E78),
                          backgroundColor: const Color(0xFFFFE7EF),
                          minimumSize: const Size(76, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: const StadiumBorder(),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(PostModel model) async {
    final analytics = ref.read(appAnalyticsProvider);
    final source = widget.analyticsSource;
    final message = model.validationMessage();
    if (message != null) {
      await analytics.logPostSubmitValidationFailed(source: source);
      if (!mounted) return;
      await showAppMessage(context, message);
      return;
    }
    await analytics.logPostSubmitAttempt(source: source);
    try {
      await model.post();
      await analytics.logPostSubmitSuccess(source: source);
      if (!mounted) return;
      await ref.read(timelineProvider).getFirstPostData();
      ref.invalidate(myPageProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(const SnackBar(content: Text('投稿しました')));
    } catch (e) {
      await analytics.logPostSubmitFailure(
        source: source,
        reason: e.toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
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
    this.lyricSegments = const [],
  });

  final VoidCallback onPick;
  final String? artist;
  final String? title;
  final String? artworkUrl;
  final String? lyrics;
  final List<String> lyricSegments;

  @override
  Widget build(BuildContext context) {
    final hasSong = (artist ?? '').isNotEmpty && (title ?? '').isNotEmpty;
    final emptyStyle = !hasSong;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPick,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(emptyStyle ? 17 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: emptyStyle
                  ? const Color(0xFFF1D4DE)
                  : const Color(0xFFECE9ED),
              width: 1,
            ),
            gradient: emptyStyle
                ? const LinearGradient(
                    colors: [Color(0xFFFFF9FB), Color(0xFFFFF1F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A17131A),
                blurRadius: 14,
                offset: Offset(0, 5),
              ),
            ],
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
                              Text(
                                title!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                artist!,
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                        const Text('変更', style: TextStyle(color: mainColor)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if ((lyrics ?? '').isEmpty)
                      const Text(
                        '歌詞の範囲を選んでください',
                        style: TextStyle(fontSize: 16, height: 1.6),
                      )
                    else
                      PostLyricsText(
                        text: lyrics ?? '',
                        segments: lyricSegments,
                        style: const TextStyle(fontSize: 16, height: 1.6),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${(lyrics ?? '').length} / 300',
                      style: const TextStyle(
                        color: Colors.black45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.library_music_rounded,
                        color: mainColor,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Text(
                        '曲と歌詞を選ぶ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: Color(0xFF0F1419),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB7AAB0),
                      size: 24,
                    ),
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
