import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/lyric_line_break_tuning.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';
import 'package:str_gram_beta/providers.dart';

/// カード全面の歌詞（投稿箇所の強調＋全文があればスクロール）。
class CardLyricsPane extends ConsumerStatefulWidget {
  const CardLyricsPane({
    super.key,
    required this.post,
    required this.maxWidth,
    required this.maxHeight,
  });

  final Post post;
  final double maxWidth;
  final double maxHeight;

  @override
  ConsumerState<CardLyricsPane> createState() => _CardLyricsPaneState();
}

class _CardLyricsPaneState extends ConsumerState<CardLyricsPane> {
  late final ScrollController _scroll;
  var _focusedIndex = 0;
  String? _fullLyrics;
  var _fetchingFull = false;

  @override
  void initState() {
    super.initState();
    _scroll = ScrollController();
    _focusedIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFullLyrics());
  }

  @override
  void didUpdateWidget(CardLyricsPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post.id != widget.post.id) {
      _fullLyrics = null;
      _focusedIndex = 0;
      _loadFullLyrics();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadFullLyrics() async {
    if (_fetchingFull) return;
    final artist = widget.post.artist.trim();
    final title = widget.post.singName.trim();
    if (artist.isEmpty || title.isEmpty) return;
    _fetchingFull = true;
    try {
      final service = ref.read(songSearchServiceProvider);
      final lyrics = await service.fetchLyrics(artist, title);
      if (!mounted) return;
      final trimmed = lyrics?.trim();
      final postedLen = widget.post.text.trim().length;
      if (trimmed != null &&
          trimmed.length > postedLen + 16 &&
          trimmed != _fullLyrics) {
        setState(() {
          _fullLyrics = trimmed;
          _focusedIndex = _indexForPostedFocus(_allBlocks());
        });
      }
    } finally {
      _fetchingFull = false;
    }
  }

  List<String> _postedSnippets() {
    final fromSeg = lyricBlocksForDisplay(widget.post);
    if (fromSeg.length > 1) return fromSeg;
    final raw =
        fromSeg.isEmpty ? widget.post.text.trim() : fromSeg.first.trim();
    if (raw.isEmpty) return const [];
    if (raw.contains('\n\n')) {
      return raw
          .split(RegExp(r'\n\n+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [raw];
  }

  static String _normalizeForMatch(String s) {
    return s.replaceAll(RegExp(r'\s+'), '');
  }

  bool _snippetMatchesBlock(String block, String snippet) {
    if (snippet.isEmpty) return false;
    final a = _normalizeForMatch(block);
    final b = _normalizeForMatch(snippet);
    if (a.isEmpty || b.isEmpty) return false;
    return a.contains(b) || b.contains(a);
  }

  bool _isPostedBlock(String block) {
    for (final snippet in _postedSnippets()) {
      if (_snippetMatchesBlock(block, snippet)) return true;
    }
    return false;
  }

  List<String> _splitFullLyrics(String full) {
    if (full.contains('\n\n')) {
      return full
          .split(RegExp(r'\n\n+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    final lines =
        full.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.length <= 10) return [full.trim()];
    const chunk = 6;
    final blocks = <String>[];
    for (var i = 0; i < lines.length; i += chunk) {
      blocks.add(lines.sublist(i, math.min(i + chunk, lines.length)).join('\n'));
    }
    return blocks;
  }

  List<String> _postOnlyBlocks() {
    final snippets = _postedSnippets();
    if (snippets.isNotEmpty) return snippets;
    return const [];
  }

  List<String> _allBlocks() {
    if (_fullLyrics != null) {
      final fromFull = _splitFullLyrics(_fullLyrics!);
      if (fromFull.length > 1) return fromFull;
    }
    return _postOnlyBlocks();
  }

  int _indexForPostedFocus(List<String> blocks) {
    for (var i = 0; i < blocks.length; i++) {
      if (_isPostedBlock(blocks[i])) return i;
    }
    return 0;
  }

  String _displayText(String block) {
    return LyricLineBreakTuning.mergeShortContinuationLines(block);
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _allBlocks();
    if (blocks.isEmpty) {
      return const SizedBox.shrink();
    }
    final focus = _focusedIndex.clamp(0, blocks.length - 1);
    final hasFullContext = _fullLyrics != null && blocks.length > 1;
    final canSwitch = blocks.length > 1;

    return SizedBox(
      height: widget.maxHeight,
      child: ListView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(2, 4, 4, 20),
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _LyricBlockTile(
              text: _displayText(blocks[i]),
              maxWidth: widget.maxWidth,
              focused: i == focus,
              isPosted: _isPostedBlock(blocks[i]),
              dimmed: i != focus,
              onTap: canSwitch ? () => setState(() => _focusedIndex = i) : null,
            ),
          ],
          if (hasFullContext)
            Padding(
              padding: const EdgeInsets.only(top: 14, left: 2),
              child: Text(
                'スクロールで曲の続き · タップで投稿箇所にフォーカス',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                  height: 1.35,
                  shadows: const [
                    Shadow(color: Color(0x99000000), blurRadius: 6),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LyricBlockTile extends StatelessWidget {
  const _LyricBlockTile({
    required this.text,
    required this.maxWidth,
    required this.focused,
    required this.isPosted,
    required this.dimmed,
    this.onTap,
  });

  final String text;
  final double maxWidth;
  final bool focused;
  final bool isPosted;
  final bool dimmed;
  final VoidCallback? onTap;

  static const _ink = [
    Shadow(blurRadius: 10, color: Color(0xAA000000)),
    Shadow(offset: Offset(0, 1), color: Color(0x99000000)),
  ];

  double _alpha() {
    if (focused) return 1;
    if (isPosted) return 0.82;
    if (dimmed) return 0.48;
    return 0.88;
  }

  @override
  Widget build(BuildContext context) {
    final body = LyricLineBreakTuning.prepareCardDisplay(
      rawText: text,
      style: TextStyle(
        fontSize: focused ? 20 : 18,
        height: 1.72,
        fontWeight: focused ? FontWeight.w600 : FontWeight.w400,
        color: Colors.white.withValues(alpha: _alpha()),
        shadows: _ink,
        letterSpacing: 0.15,
      ),
      maxWidth: maxWidth,
      textAlign: TextAlign.left,
    );

    Widget child = Text(
      body.text,
      style: body.style,
      textAlign: TextAlign.left,
    );

    if (onTap != null) {
      child = GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }

    return child;
  }
}
