import 'package:flutter/material.dart';

/// カード歌詞：7文字未満の行だけを避け、**全文同じフォントサイズ**で表示する。
class LyricLineBreakTuning {
  LyricLineBreakTuning._();

  static const minOrphanLineLength = 7;

  static String mergeShortContinuationLines(String text) {
    if (!text.contains('\n')) return text;
    final raw = text.split('\n');
    final out = <String>[];
    var buffer = '';

    void flushBuffer() {
      final t = buffer.trim();
      if (t.isNotEmpty) out.add(t);
      buffer = '';
    }

    for (final rawLine in raw) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        flushBuffer();
        continue;
      }
      if (buffer.isEmpty) {
        buffer = line;
        continue;
      }
      if (line.characters.length < minOrphanLineLength) {
        buffer = '$buffer$line';
      } else {
        flushBuffer();
        buffer = line;
      }
    }
    flushBuffer();
    return out.join('\n');
  }

  static List<String> mergeShortSegments(List<String> segments) {
    if (segments.length <= 1) return segments;
    final out = <String>[];
    var buffer = segments.first.trim();
    for (var i = 1; i < segments.length; i++) {
      final part = segments[i].trim();
      if (part.isEmpty) continue;
      if (part.characters.length < minOrphanLineLength) {
        buffer = '$buffer$part';
      } else {
        if (buffer.isNotEmpty) out.add(buffer);
        buffer = part;
      }
    }
    if (buffer.isNotEmpty) out.add(buffer);
    return out;
  }

  static List<String> visualLines(TextPainter painter, String text) {
    final metrics = painter.computeLineMetrics();
    if (metrics.isEmpty) return [text];

    final lines = <String>[];
    var start = 0;
    for (var i = 0; i < metrics.length; i++) {
      final end = i < metrics.length - 1
          ? painter
              .getPositionForOffset(
                Offset(0, metrics[i + 1].baseline),
              )
              .offset
          : text.length;
      final safeEnd = end.clamp(start, text.length);
      if (safeEnd <= start) continue;
      final slice = text.substring(start, safeEnd);
      if (slice.trim().isNotEmpty) {
        lines.add(slice.replaceAll('\n', ' ').trim());
      }
      start = safeEnd;
    }
    return lines;
  }

  static bool _linesHaveShortOrphan(List<String> lines) {
    if (lines.length <= 1) return false;
    for (final line in lines) {
      final len = line.characters.length;
      if (len > 0 && len < minOrphanLineLength) return true;
    }
    return false;
  }

  static List<String> mergeShortVisualLines(List<String> lines) {
    if (lines.length <= 1) return lines;
    final out = <String>[];
    for (final line in lines) {
      if (out.isNotEmpty && line.characters.length < minOrphanLineLength) {
        out[out.length - 1] = '${out.last}$line';
      } else {
        out.add(line);
      }
    }
    return out;
  }

  static TextPainter _painter(
    String text,
    TextStyle style,
    double maxWidth,
    TextAlign textAlign,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter;
  }

  static bool hasShortOrphanLine({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.center,
  }) {
    if (text.trim().isEmpty) return false;
    final lines = visualLines(_painter(text, style, maxWidth, textAlign), text);
    return _linesHaveShortOrphan(lines);
  }

  /// 折り返しでできた短い行を前行へ寄せる（フォントサイズは変えない）。
  static String reflowShortVisualLines({
    required String text,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.center,
  }) {
    var current = text;
    for (var pass = 0; pass < 12; pass++) {
      final painter = _painter(current, style, maxWidth, textAlign);
      var lines = visualLines(painter, current);
      if (!_linesHaveShortOrphan(lines)) return current;
      lines = mergeShortVisualLines(lines);
      final next = lines.join('\n');
      if (next == current) return current;
      current = next;
    }
    return current;
  }

  /// カード用：フォントサイズは変えず、短い行だけ結合して折り返す。
  static ({String text, TextStyle style}) prepareCardDisplay({
    required String rawText,
    required TextStyle style,
    required double maxWidth,
    TextAlign textAlign = TextAlign.start,
  }) {
    final normalized = mergeShortContinuationLines(rawText);
    final reflowed = reflowShortVisualLines(
      text: normalized,
      style: style,
      maxWidth: maxWidth,
      textAlign: textAlign,
    );
    return (text: reflowed, style: style);
  }
}

class LyricTextTunedForWidth extends StatelessWidget {
  const LyricTextTunedForWidth({
    super.key,
    required this.text,
    required this.style,
    required this.maxWidth,
    this.textAlign = TextAlign.center,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle style;
  final double maxWidth;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final prepared = LyricLineBreakTuning.prepareCardDisplay(
      rawText: text,
      style: style,
      maxWidth: maxWidth,
      textAlign: textAlign,
    );
    return Text(
      prepared.text,
      style: prepared.style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
