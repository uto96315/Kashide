import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/song/song_quote.dart';
import 'package:str_gram_beta/song/song_search_service.dart';

class SongPickPage extends StatefulWidget {
  const SongPickPage({super.key});

  @override
  State<SongPickPage> createState() => _SongPickPageState();
}

class _SongPickPageState extends State<SongPickPage> {
  final _service = SongSearchService();
  final _controller = TextEditingController();
  List<SongHit> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ScreenTop(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: '曲名や歌手名',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (_) => _search(),
            ),
          ),
          if (_loading) const LinearProgressIndicator(color: mainColor),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, style: const TextStyle(color: Colors.black54)),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final song = _results[index];
                return ListTile(
                  leading: _Artwork(url: song.artworkUrl),
                  title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final quote = await Navigator.push<SongQuote>(
                      context,
                      MaterialPageRoute(builder: (_) => LyricsSelectPage(song: song)),
                    );
                    if (quote != null && context.mounted) {
                      Navigator.pop(context, quote);
                    }
                  },
                );
              },
            ),
          ),
        ],
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
  String? _lyrics;
  String _selected = '';
  bool _loading = true;
  String? _error;
  bool _showGuide = true;

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
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.paddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '歌詞の選び方',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              _tutorialStep('1', '歌詞のどこかを長押し', Icons.touch_app_rounded),
              _tutorialStep('2', '載せたい始点〜終点まで範囲を広げる', Icons.swipe_rounded),
              _tutorialStep('3', '下の「この範囲を載せる」を押す', Icons.check_circle_outline_rounded),
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
            child: Text(n, style: const TextStyle(color: mainColor, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4)),
            ),
          ),
          Icon(icon, color: mainColor, size: 26),
        ],
      ),
    );
  }

  Future<void> _load() async {
    try {
      final lyrics = await _service.fetchLyrics(widget.song.artist, widget.song.title);
      if (!mounted) return;
      setState(() {
        _lyrics = lyrics;
        _loading = false;
        if (lyrics == null || lyrics.isEmpty) {
          _error = 'この曲の歌詞が見つかりませんでした';
        } else {
          _maybeShowTutorial();
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

  bool get _canUse =>
      _selected.isNotEmpty && _selected.length <= SongSearchService.lyricsLimit;

  @override
  Widget build(BuildContext context) {
    final count = _selected.length;
    final over = count > SongSearchService.lyricsLimit;
    return Scaffold(
      body: Column(
        children: [
          ScreenTop(title: widget.song.title),
          Expanded(
            child: _loading
          ? const Center(child: CircularProgressIndicator(color: mainColor))
          : _lyrics == null
              ? Center(child: Text(_error ?? '歌詞がありません'))
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
                                Text(widget.song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(widget.song.artist, style: const TextStyle(color: Colors.black54)),
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
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _maybeShowTutorial(force: true),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: mainColor.withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_outline_rounded, color: mainColor, size: 22),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      '長押し → 範囲を調整 →「この範囲を載せる」',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        height: 1.35,
                                        color: Color(0xFF0F1419),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    onPressed: () => setState(() => _showGuide = false),
                                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF536471)),
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
                        child: SelectableText(
                          _lyrics!,
                          style: const TextStyle(fontSize: 16, height: 1.7),
                          onSelectionChanged: (selection, _) {
                            final text = _lyrics!;
                            final start = selection.start.clamp(0, text.length);
                            final end = selection.end.clamp(start, text.length);
                            setState(() {
                              _selected = text.substring(start, end).trim();
                              if (_selected.isNotEmpty) _showGuide = false;
                            });
                          },
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            over
                                ? '選択は${SongSearchService.lyricsLimit}文字までです（$count文字）'
                                : _selected.isEmpty
                                    ? 'まだ範囲が選ばれていません'
                                    : '選択中 $count / ${SongSearchService.lyricsLimit}文字',
                            style: TextStyle(color: over ? Colors.red : Colors.black54),
                          ),
                          if (_selected.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(_selected, maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _canUse
                                  ? () {
                                      Navigator.pop(
                                        context,
                                        SongQuote(
                                          artist: widget.song.artist,
                                          title: widget.song.title,
                                          lyrics: _selected,
                                          listenUrl: widget.song.listenUrl,
                                          artworkUrl: widget.song.artworkUrl,
                                        ),
                                      );
                                    }
                                  : null,
                              child: const Text('この範囲を載せる'),
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
