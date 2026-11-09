import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/lyric_line_break_tuning.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';

/// 投稿の歌詞（1箇所 or 複数箇所）を表示する。
class PostLyricsText extends StatelessWidget {
  const PostLyricsText({
    super.key,
    required this.text,
    this.segments = const [],
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tuneLineBreaks = false,
    this.layoutMaxWidth,
  });

  PostLyricsText.fromPost(
    Post post, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.tuneLineBreaks = false,
    this.layoutMaxWidth,
  })  : text = post.text,
        segments = post.textSegments;

  final String text;
  final List<String> segments;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool tuneLineBreaks;
  final double? layoutMaxWidth;

  Widget _textForBlock(String block, TextStyle base) {
    final align = textAlign ?? TextAlign.start;
    if (tuneLineBreaks && layoutMaxWidth != null && layoutMaxWidth! > 0) {
      return LyricTextTunedForWidth(
        text: block,
        style: base,
        maxWidth: layoutMaxWidth!,
        textAlign: align,
        maxLines: maxLines,
        overflow: overflow,
      );
    }
    return Text(
      block,
      style: base,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  String _rawLyricsForCard() {
    String raw;
    if (segments.length > 1) {
      raw = LyricLineBreakTuning.mergeShortSegments(segments).join('\n');
    } else {
      final trimmed = text.trim();
      raw = trimmed.isNotEmpty
          ? trimmed
          : (segments.isEmpty ? '' : segments.first);
    }
    return LyricLineBreakTuning.mergeShortContinuationLines(raw);
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? const TextStyle(fontSize: 16, height: 1.55);

    if (tuneLineBreaks && layoutMaxWidth != null && layoutMaxWidth! > 0) {
      return _textForBlock(_rawLyricsForCard(), base);
    }

    final post = Post(
      '',
      '',
      text,
      '',
      0,
      const [],
      '',
      '',
      '',
      '',
      0,
      '',
      '',
      textSegments: segments,
    );
    final blocks = lyricBlocksForDisplay(post);

    if (blocks.length <= 1) {
      return _textForBlock(blocks.isEmpty ? text : blocks.first, base);
    }

    final crossAlign = switch (textAlign) {
      TextAlign.center => CrossAxisAlignment.center,
      TextAlign.right || TextAlign.end => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.stretch,
    };
    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Color(0x33000000)),
            const SizedBox(height: 10),
          ],
          _textForBlock(blocks[i], base),
        ],
      ],
    );
  }
}
