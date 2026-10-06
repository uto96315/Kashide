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
    final uri = Uri.https('itunes.apple.com', '/search', {
      'term': term,
      'entity': 'song',
      'limit': '25',
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
