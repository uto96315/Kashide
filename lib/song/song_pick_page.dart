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
  final _service = SongSearchService();
  String? _lyrics;
  String _selected = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
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
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(
                        '載せたい範囲をドラッグして選んでください',
                        style: TextStyle(color: Colors.black54),
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
