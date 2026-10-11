import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';
import 'package:str_gram_beta/post/post_validation.dart';
import 'package:str_gram_beta/song/song_quote.dart';
import 'package:str_gram_beta/song/song_search_service.dart';

class SongPickPage extends StatefulWidget {
  const SongPickPage({super.key});

  @override
  State<SongPickPage> createState() => _SongPickPageState();
}

class _SongPickPageState extends State<SongPickPage> {
  static const _recommendedArtists = [
    'Saucy Dog',
    'Mr.Children',
    'aiko',
    'back number',
    '米津玄師',
    '加藤ミリヤ',
    'Aimer',
    'Mrs. GREEN APPLE',
    'レミオロメン',
    'wacci',
  ];

  final _service = SongSearchService();
  final _controller = TextEditingController();
  final _manualArtistController = TextEditingController();
  final _manualTitleController = TextEditingController();
  List<SongHit> _results = [];
  int _visibleResultCount = 25;
  bool _loading = false;
  bool _enteringSongManually = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _manualArtistController.dispose();
    _manualTitleController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _visibleResultCount = 25;
    });
    try {
      final results = await _service.searchSongs(query);
      if (!mounted) return;
      setState(() {
        _results = results;
        _loading = false;
        if (results.isEmpty) _error = '曲が見つかりませんでした';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '検索できませんでした。通信環境を確認してください';
      });
    }
  }

  void _searchArtist(String artist) {
    _controller
      ..text = artist
      ..selection = TextSelection.collapsed(offset: artist.length);
    _search();
  }

  Future<void> _openSong(SongHit song) async {
    final quote = await Navigator.push<SongQuote>(
      context,
      MaterialPageRoute(builder: (_) => LyricsSelectPage(song: song)),
    );
    if (quote != null && mounted) Navigator.pop(context, quote);
  }

  Future<void> _openManualSong() async {
    final artist = _manualArtistController.text.trim();
    final title = _manualTitleController.text.trim();
    if (artist.isEmpty || title.isEmpty) return;
    FocusScope.of(context).unfocus();
    await _openSong(SongHit(artist: artist, title: title, listenUrl: ''));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Column(
        children: [
          const ScreenTop(title: '曲を選ぶ'),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '曲名やアーティスト名',
                hintStyle: const TextStyle(color: Color(0xFF98959C)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF8E8991),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconButton.filled(
                    tooltip: '検索',
                    onPressed: _loading ? null : _search,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFFFEAF0),
                      foregroundColor: const Color(0xFFB66480),
                      disabledBackgroundColor: const Color(0xFFF6EDF0),
                      shape: const CircleBorder(),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  ),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE9E6EA)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFFE9E6EA)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(
                    color: Color(0xFFD8B5C1),
                    width: 1.2,
                  ),
                ),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: mainColor),
          Expanded(
            child: _results.isNotEmpty
                ? _buildResults()
                : _error != null
                ? _buildSearchError()
                : _buildRecommendations(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 20),
      children: [
        const Text(
          'アーティストから探す',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF24232A),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'アーティストを選ぶと曲を検索します',
          style: TextStyle(fontSize: 13, color: Color(0xFF85818A)),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - 8) / 2;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final artist in _recommendedArtists)
                  SizedBox(
                    width: itemWidth,
                    height: 58,
                    child: _ArtistSuggestion(
                      name: artist,
                      onTap: _loading ? null : () => _searchArtist(artist),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResults() {
    final visibleCount = _visibleResultCount.clamp(0, _results.length);
    final hasMore = visibleCount < _results.length;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
      itemCount: visibleCount + (hasMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == visibleCount) {
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: OutlinedButton.icon(
              onPressed: () => setState(() {
                _visibleResultCount += 25;
              }),
              icon: const Icon(Icons.expand_more_rounded),
              label: const Text('さらに読み込む'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8E6473),
                side: const BorderSide(color: Color(0xFFE8D8DE)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          );
        }
        final song = _results[index];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () async {
              final quote = await Navigator.push<SongQuote>(
                context,
                MaterialPageRoute(builder: (_) => LyricsSelectPage(song: song)),
              );
              if (quote != null && context.mounted) {
                Navigator.pop(context, quote);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEBE7EC)),
              ),
              child: Row(
                children: [
                  _Artwork(url: song.artworkUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF28262D),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          song.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF85818A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFAAA5AD),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchError() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 24),
      child: Column(
        children: [
          if (!_enteringSongManually) ...[
            const Icon(
              Icons.music_off_rounded,
              size: 38,
              color: Color(0xFFB9B3BB),
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF69656D), height: 1.5),
            ),
            const SizedBox(height: 8),
            const Text(
              '曲名やアーティスト名を変えて検索できます。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF96919A)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => setState(() => _enteringSongManually = true),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('曲名とアーティスト名を入力する'),
            ),
          ] else ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '曲を手入力',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _manualArtistController,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(labelText: 'アーティスト名'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _manualTitleController,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _openManualSong(),
              decoration: const InputDecoration(labelText: '曲名'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _manualArtistController.text.trim().isNotEmpty &&
                        _manualTitleController.text.trim().isNotEmpty
                    ? _openManualSong
                    : null,
                child: const Text('この曲で歌詞を選ぶ'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _enteringSongManually = false),
              child: const Text('検索に戻る'),
            ),
          ],
        ],
      ),
    );
  }
}

class _ArtistSuggestion extends StatelessWidget {
  const _ArtistSuggestion({required this.name, required this.onTap});

  final String name;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xFFE9E6EA)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.music_note_rounded,
                color: Color(0xFFB78394),
                size: 19,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF39363D),
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFB7B2BA),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LyricsSelectPage extends StatefulWidget {
  const LyricsSelectPage({super.key, required this.song});

  final SongHit song;

  @override
  State<LyricsSelectPage> createState() => _LyricsSelectPageState();
}

class _LyricsSelectPageState extends State<LyricsSelectPage> {
  static var _lyricsPickTutorialShown = false;

  final _service = SongSearchService();
  final _manualLyricsController = TextEditingController();
  String? _lyrics;
  String _selected = '';
  int? _selectionStartLine;
  int? _selectionEndLine;
  final List<String> _segments = [];
  bool _loading = true;
  String? _error;
  bool _showGuide = true;
  bool _enteringLyrics = false;

  @override
  void dispose() {
    _manualLyricsController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _maybeShowTutorial({bool force = false}) {
    if (!force && _lyricsPickTutorialShown) return;
    if (!force) _lyricsPickTutorialShown = true;
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (ctx) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            20 + MediaQuery.paddingOf(ctx).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '歌詞の選び方',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _tutorialStep('1', '使いたい範囲の最初の行をタップ', Icons.touch_app_rounded),
              _tutorialStep('2', '最後の行をタップして範囲を決める', Icons.swipe_rounded),
              _tutorialStep(
                '3',
                '「追加」で複数箇所もOK。最後に「これで決定」',
                Icons.check_circle_outline_rounded,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK、選んでみる'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _tutorialStep(String n, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: mainColor.withValues(alpha: 0.15),
            child: Text(
              n,
              style: const TextStyle(
                color: mainColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(fontSize: 16, height: 1.4),
              ),
            ),
          ),
          Icon(icon, color: mainColor, size: 26),
        ],
      ),
    );
  }

  Future<void> _load() async {
    try {
      final lyrics = await _service.fetchLyrics(
        widget.song.artist,
        widget.song.title,
      );
      if (!mounted) return;
      final availableLyrics = lyrics?.trim().isNotEmpty == true ? lyrics : null;
      setState(() {
        _lyrics = availableLyrics;
        _loading = false;
        if (availableLyrics == null) {
          _error = 'この曲の歌詞が見つかりませんでした';
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '歌詞を取得できませんでした';
      });
    }
  }

  int get _combinedLength {
    final pending = [..._segments, if (_selected.isNotEmpty) _selected];
    return combineLyricSegments(pending).length;
  }

  bool get _selectionOverLimit =>
      _selected.length > SongSearchService.lyricsLimit;

  bool get _totalOverLimit => _combinedLength > postLyricsLimit;

  bool get _canAdd =>
      _selected.isNotEmpty &&
      !_selectionOverLimit &&
      !_totalOverLimit &&
      _segments.length < maxLyricSegments;

  List<String> get _pendingSegments {
    final segments = List<String>.from(_segments);
    if (_selected.isNotEmpty) segments.add(_selected.trim());
    return segments;
  }

  bool get _canFinish {
    final segments = _pendingSegments;
    if (segments.isEmpty) return false;
    final combined = combineLyricSegments(segments);
    if (combined.length > postLyricsLimit) return false;
    if (combined.length < postLyricsMinLength) return false;
    return true;
  }

  void _addSegment() {
    if (!_canAdd) return;
    setState(() {
      _segments.add(_selected.trim());
      _selected = '';
      _selectionStartLine = null;
      _selectionEndLine = null;
    });
  }

  void _selectLyricLine(int index) {
    final lines = _lyrics!.split('\n');
    setState(() {
      if (_selectionStartLine == null || _selectionEndLine != null) {
        _selectionStartLine = index;
        _selectionEndLine = null;
        _selected = '';
        return;
      }

      _selectionEndLine = index;
      final first = _selectionStartLine! < index ? _selectionStartLine! : index;
      final last = _selectionStartLine! > index ? _selectionStartLine! : index;
      _selected = lines.sublist(first, last + 1).join('\n').trim();
      _showGuide = false;
    });
  }

  Future<void> _fineTuneSelection() async {
    if (_selected.isEmpty) return;
    final adjusted = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _LyricRangeFineTuneSheet(text: _selected),
    );
    if (!mounted || adjusted == null || adjusted.isEmpty) return;
    setState(() {
      _selected = adjusted;
      // The line highlight describes the coarse range. Once adjusted by
      // character, the preview is the source of truth instead.
      _selectionStartLine = null;
      _selectionEndLine = null;
      _showGuide = false;
    });
  }

  Widget _buildLyricLine(String line, int index) {
    final start = _selectionStartLine;
    final end = _selectionEndLine;
    final isSelected =
        start != null &&
        end != null &&
        index >= (start < end ? start : end) &&
        index <= (start > end ? start : end);
    final isAnchor = start == index && end == null;

    if (line.trim().isEmpty) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isAnchor
            ? const Color(0xFFFFE4EC)
            : isSelected
            ? const Color(0xFFFFF1F5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _selectLyricLine(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAnchor)
                  Padding(
                    padding: const EdgeInsets.only(right: 6, top: 3),
                    child: Container(
                      width: 3,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE76C91),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.55,
                      color: isAnchor || isSelected
                          ? const Color(0xFF3B3035)
                          : const Color(0xFF38343A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _removeSegment(int index) {
    setState(() => _segments.removeAt(index));
  }

  void _useManualLyrics() {
    final lyrics = _manualLyricsController.text.trim();
    if (lyrics.length < postLyricsMinLength) return;
    setState(() {
      _lyrics = lyrics;
      _selected = '';
      _segments.clear();
      _error = null;
      _enteringLyrics = false;
      _showGuide = true;
    });
  }

  Widget _buildMissingLyrics() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Artwork(url: widget.song.artworkUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.song.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      widget.song.artist,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          if (!_enteringLyrics) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lyrics_outlined,
                      size: 38,
                      color: Color(0xFFB9B3BB),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _error ?? 'この曲の歌詞が見つかりませんでした',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF49464D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '歌詞を入力して、載せたい範囲を選べます',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Color(0xFF85818A)),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () => setState(() => _enteringLyrics = true),
                      icon: const Icon(Icons.edit_note_rounded),
                      label: const Text('歌詞を入力する'),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('別の曲を選ぶ'),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            const Text(
              '歌詞を入力',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '歌詞サイトなどで確認した内容を貼り付けてください。投稿前に載せる範囲を選べます。',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Color(0xFF777780),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _manualLyricsController,
                autofocus: true,
                expands: true,
                minLines: null,
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'ここに歌詞を貼り付け',
                  filled: true,
                  fillColor: Colors.white,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E3E8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFFD8B5C1),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _manualLyricsController.text.trim().length >=
                        postLyricsMinLength
                    ? _useManualLyrics
                    : null,
                child: const Text('歌詞を確認して範囲を選ぶ'),
              ),
            ),
            Center(
              child: TextButton(
                onPressed: () => setState(() => _enteringLyrics = false),
                child: const Text('戻る'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _finish() {
    final segments = _pendingSegments;
    final combined = combineLyricSegments(segments);
    Navigator.pop(
      context,
      SongQuote(
        artist: widget.song.artist,
        title: widget.song.title,
        lyrics: combined,
        listenUrl: widget.song.listenUrl,
        artworkUrl: widget.song.artworkUrl,
        lyricSegments: segments.length > 1 ? segments : const [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    final over = _selectionOverLimit;
    final totalLen = _combinedLength;
    return Scaffold(
      body: Column(
        children: [
          ScreenTop(title: widget.song.title),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: mainColor),
                  )
                : _lyrics == null
                ? _buildMissingLyrics()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            _Artwork(url: widget.song.artworkUrl),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.song.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    widget.song.artist,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_showGuide && _selected.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Material(
                            color: const Color(0xFFFFF0F5),
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _maybeShowTutorial(force: true),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(12, 9, 6, 9),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: mainColor.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.lightbulb_outline_rounded,
                                      color: mainColor,
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _selectionStartLine == null
                                            ? '最初の行をタップして、範囲の始まりを選びます'
                                            : '最後の行をタップすると、範囲が決まります',
                                        style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: Color(0xFF65545B),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      onPressed: () =>
                                          setState(() => _showGuide = false),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 20,
                                        color: Color(0xFF536471),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in _lyrics!.split('\n').indexed)
                                _buildLyricLine(entry.$2, entry.$1),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              over
                                  ? '1回の選択は${SongSearchService.lyricsLimit}文字まで（$count文字）'
                                  : _totalOverLimit
                                  ? '合計は$postLyricsLimit文字まで（現在 $totalLen 文字）'
                                  : _selectionStartLine != null &&
                                        _selectionEndLine == null
                                  ? '範囲の最後の行をタップしてください'
                                  : _selected.isEmpty && _segments.isEmpty
                                  ? '最初の行と最後の行をタップして範囲を選択'
                                  : '合計 $totalLen / $postLyricsLimit文字 · ${_segments.length}箇所追加済み',
                              style: TextStyle(
                                color: (over || _totalOverLimit)
                                    ? Colors.red
                                    : Colors.black54,
                              ),
                            ),
                            if (_selected.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _selected,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _fineTuneSelection,
                                  icon: const Icon(
                                    Icons.tune_rounded,
                                    size: 17,
                                  ),
                                  label: const Text('範囲を微調整'),
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: const Color(0xFF9D6477),
                                  ),
                                ),
                              ),
                            ],
                            if (_segments.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              for (var i = 0; i < _segments.length; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Material(
                                    color: const Color(0xFFFFF7F8),
                                    borderRadius: BorderRadius.circular(10),
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        _segments[i],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: () => _removeSegment(i),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                            const SizedBox(height: 12),
                            if (_segments.length < maxLyricSegments)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _canAdd ? _addSegment : null,
                                  child: Text(
                                    _segments.isEmpty
                                        ? 'この範囲を追加'
                                        : '別の箇所を追加（${_segments.length}/$maxLyricSegments）',
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _canFinish ? _finish : null,
                                child: Text(
                                  _pendingSegments.length <= 1
                                      ? 'この範囲で決定'
                                      : 'これで決定（${_pendingSegments.length}箇所）',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LyricRangeFineTuneSheet extends StatefulWidget {
  const _LyricRangeFineTuneSheet({required this.text});

  final String text;

  @override
  State<_LyricRangeFineTuneSheet> createState() =>
      _LyricRangeFineTuneSheetState();
}

class _LyricRangeFineTuneSheetState extends State<_LyricRangeFineTuneSheet> {
  String _adjustedText = '';

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.62;
    return SafeArea(
      child: SizedBox(
        height: sheetHeight,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            16 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '範囲を微調整',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                '歌詞を長押しし、両端のハンドルを動かしてください',
                style: TextStyle(fontSize: 13, color: Color(0xFF85818A)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    widget.text,
                    style: const TextStyle(fontSize: 17, height: 1.7),
                    onSelectionChanged: (selection, _) {
                      if (selection.isCollapsed) return;
                      final start = selection.start.clamp(
                        0,
                        widget.text.length,
                      );
                      final end = selection.end.clamp(
                        start,
                        widget.text.length,
                      );
                      final selected = widget.text.substring(start, end).trim();
                      if (selected.isEmpty || selected == _adjustedText) return;
                      setState(() => _adjustedText = selected);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _adjustedText.isEmpty ? '調整後の範囲がここに表示されます' : _adjustedText,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _adjustedText.isEmpty
                        ? const Color(0xFF96919A)
                        : const Color(0xFF49434A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _adjustedText.isEmpty
                      ? null
                      : () => Navigator.pop(context, _adjustedText),
                  child: const Text('この範囲にする'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({this.url});

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
