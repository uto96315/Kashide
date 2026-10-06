import 'dart:convert';

import 'package:http/http.dart' as http;

import 'song_quote.dart';

class SongHit {
  const SongHit({
    required this.artist,
    required this.title,
    required this.listenUrl,
    this.artworkUrl,
  });

  final String artist;
  final String title;
  final String listenUrl;
  final String? artworkUrl;
}

class SongSearchService {
  static const lyricsLimit = 300;

  Future<List<SongHit>> searchSongs(String query) async {
    final term = query.trim();
    if (term.isEmpty) return [];
    return _fetchSongHits(term: term, limit: 25);
  }

  /// Firestore に再生 URL が無い投稿向けに Apple Music（iTunes）の曲ページ URL を探す。
  Future<String?> lookupTrackUrl({
    required String artist,
    required String title,
  }) async {
    final a = artist.trim();
    final t = title.trim();
    if (a.isEmpty || t.isEmpty || a == '不明' || t == '不明') return null;

    final hits = await _fetchSongHits(term: '$a $t', limit: 8);
    if (hits.isEmpty) return null;

    for (final hit in hits) {
      if (_namesMatch(hit.artist, a) && _namesMatch(hit.title, t)) {
        return _nonEmptyUrl(hit.listenUrl);
      }
    }
    for (final hit in hits) {
      if (_namesMatch(hit.artist, a)) {
        return _nonEmptyUrl(hit.listenUrl);
      }
    }
    return _nonEmptyUrl(hits.first.listenUrl);
  }

  Future<List<SongHit>> _fetchSongHits({
    required String term,
    required int limit,
  }) async {
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': 'song',
      'limit': '$limit',
      'country': 'JP',
      'lang': 'ja_jp',
    });
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('曲の検索に失敗しました');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);
    return results.map((raw) {
      final item = raw as Map<String, dynamic>;
      return SongHit(
        artist: (item['artistName'] as String?) ?? '',
        title: (item['trackName'] as String?) ?? '',
        listenUrl: (item['trackViewUrl'] as String?) ?? '',
        artworkUrl: item['artworkUrl100'] as String?,
      );
    }).where((song) => song.artist.isNotEmpty && song.title.isNotEmpty).toList();
  }

  static String _normalizeName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static bool _namesMatch(String a, String b) =>
      _normalizeName(a) == _normalizeName(b);

  static String? _nonEmptyUrl(String url) {
    final trimmed = url.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<String?> fetchLyrics(String artist, String title) async {
    final direct = Uri.https('lrclib.net', '/api/get', {
      'artist_name': artist,
      'track_name': title,
    });
    final directResponse = await http.get(direct, headers: _headers);
    if (directResponse.statusCode == 200) {
      final lyrics = _plainLyrics(directResponse.body);
      if (lyrics != null && lyrics.isNotEmpty) return lyrics;
    }

    final search = Uri.https('lrclib.net', '/api/search', {
      'artist_name': artist,
      'track_name': title,
    });
    final searchResponse = await http.get(search, headers: _headers);
    if (searchResponse.statusCode != 200) return null;
    final list = jsonDecode(searchResponse.body);
    if (list is! List || list.isEmpty) return null;
    for (final raw in list) {
      if (raw is Map<String, dynamic>) {
        final lyrics = raw['plainLyrics'] as String?;
        if (lyrics != null && lyrics.trim().isNotEmpty) return lyrics.trim();
      }
    }
    return null;
  }

  String? _plainLyrics(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      final lyrics = decoded['plainLyrics'] as String?;
      return lyrics?.trim();
    }
    return null;
  }

  static const _headers = {'User-Agent': 'Kashide/1.1.3 (lyrics quote picker)'};
}

SongQuote quoteFromSelection({
  required SongHit song,
  required String lyrics,
  required int start,
  required int end,
}) {
  final safeStart = start.clamp(0, lyrics.length);
  final safeEnd = end.clamp(safeStart, lyrics.length);
  return SongQuote(
    artist: song.artist,
    title: song.title,
    lyrics: lyrics.substring(safeStart, safeEnd).trim(),
    listenUrl: song.listenUrl,
    artworkUrl: song.artworkUrl,
  );
}
