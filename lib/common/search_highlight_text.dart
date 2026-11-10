import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/search/post_search_matcher.dart';

/// 検索語を [mainColor] でハイライトした Text。
class SearchHighlightText extends StatelessWidget {
  const SearchHighlightText({
    super.key,
    required this.text,
    required this.query,
    required this.style,
    this.maxLines,
    this.overflow,
    this.extraNeedles = const {},
    this.textAlign = TextAlign.start,
  });

  final String text;
  final String query;
  final TextStyle style;
  final int? maxLines;
  final TextOverflow? overflow;
  final Set<String> extraNeedles;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final needles = PostSearchMatcher.highlightNeedles(query, extra: extraNeedles);
    if (text.isEmpty || needles.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    final lower = text.toLowerCase();
    final ranges = <({int start, int end})>[];

    for (final needle in needles) {
      final n = needle.toLowerCase();
      if (n.isEmpty) continue;
      var from = 0;
      while (true) {
        final i = lower.indexOf(n, from);
        if (i < 0) break;
        ranges.add((start: i, end: i + needle.length));
        from = i + 1;
      }
    }

    if (ranges.isEmpty) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );
    }

    ranges.sort((a, b) => a.start.compareTo(b.start));
    final merged = <({int start, int end})>[];
    for (final r in ranges) {
      if (merged.isEmpty || r.start > merged.last.end) {
        merged.add(r);
      } else if (r.end > merged.last.end) {
        merged[merged.length - 1] = (
          start: merged.last.start,
          end: r.end,
        );
      }
    }

    final highlightStyle = style.copyWith(
      color: mainColor,
      backgroundColor: mainColor.withValues(alpha: 0.14),
      fontWeight: FontWeight.w700,
    );

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final r in merged) {
      if (r.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, r.start), style: style));
      }
      spans.add(TextSpan(text: text.substring(r.start, r.end), style: highlightStyle));
      cursor = r.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: style));
    }

    return Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}
