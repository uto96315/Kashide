import 'package:flutter/material.dart';
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
  });

  PostLyricsText.fromPost(
    Post post, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  })  : text = post.text,
        segments = post.textSegments;

  final String text;
  final List<String> segments;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
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
    final base = style ?? const TextStyle(fontSize: 16, height: 1.55);

    if (blocks.length <= 1) {
      return Text(
        blocks.isEmpty ? text : blocks.first,
        style: base,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: Color(0x33000000)),
            const SizedBox(height: 10),
          ],
          Text(
            blocks[i],
            style: base,
            textAlign: textAlign,
            maxLines: maxLines,
            overflow: overflow,
          ),
        ],
      ],
    );
  }
}
