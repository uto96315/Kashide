import 'dart:convert';

import 'package:http/http.dart' as http;

import 'song_quote.dart';

class SongHit {
  const SongHit({
    required this.artist,
    required this.title,
    required this.listenUrl,
    this.previewUrl,
    this.artworkUrl,
  });

  final String artist;
  final String title;
  final String listenUrl;
  final String? previewUrl;
  final String? artworkUrl;
}

enum SongSearchField { any, artist, title }

class SongSearchService {
  static const lyricsLimit = 300;

  Future<List<SongHit>> searchSongs(
    String query, {
    SongSearchField field = SongSearchField.any,
  }) async {
    final term = query.trim();
    if (term.isEmpty) return [];

    if (field == SongSearchField.any) {
      final pair = _splitArtistAndTitle(term);
      final searches = pair == null
          ? await Future.wait([
              _fetchSongHits(term: term, limit: 200),
              _fetchSongHits(term: term, limit: 200, attribute: 'artistTerm'),
              _fetchSongHits(term: term, limit: 200, attribute: 'songTerm'),
            ])
          : await Future.wait([
              _fetchSongHits(term: term, limit: 200),
              _fetchSongHits(
                term: pair.artist,
                limit: 200,
                attribute: 'artistTerm',
              ),
              _fetchSongHits(
                term: pair.title,
                limit: 200,
                attribute: 'songTerm',
              ),
            ]);

      final merged = <SongHit>[];
      final seen = <String>{};
      void addAll(Iterable<SongHit> songs) {
        for (final song in songs) {
          final key =
              '${_compactName(song.artist)}|${_compactName(song.title)}';
          if (seen.add(key)) merged.add(song);
        }
      }

      addAll(searches[0]);
      if (pair != null) {
        final artist = _compactName(pair.artist);
        final matchingArtist = searches[2].where(
          (song) => _compactName(song.artist).contains(artist),
        );
        addAll(matchingArtist);
        addAll(searches[2]);
        addAll(searches[1]);
      } else {
        addAll(searches[1]);
        addAll(searches[2]);
      }
      return merged;
    }

    // General search first, then search the catalog fields independently. The
    // iTunes API can return different matches for the same words depending on
    // whether they match an artist or a track title.
    final attributes = switch (field) {
      SongSearchField.any => <String?>[null],
      SongSearchField.artist => <String?>['artistTerm', null],
      SongSearchField.title => <String?>['songTerm', null],
    };
    for (final attribute in attributes) {
      final hits = await _fetchSongHits(
        term: term,
        limit: 200,
        attribute: attribute,
      );
      if (hits.isNotEmpty) return hits;
    }
    return [];
  }

  static _ArtistAndTitle? _splitArtistAndTitle(String query) {
    final explicit = RegExp(r'\s+[-–—|/]\s+').firstMatch(query);
    if (explicit != null) {
      final artist = query.substring(0, explicit.start).trim();
      final title = query.substring(explicit.end).trim();
      if (artist.isNotEmpty && title.isNotEmpty) {
        return _ArtistAndTitle(artist, title);
      }
    }

    final lastSpace = query.lastIndexOf(RegExp(r'\s'));
    if (lastSpace <= 0 || lastSpace == query.length - 1) return null;
    return _ArtistAndTitle(
      query.substring(0, lastSpace).trim(),
      query.substring(lastSpace + 1).trim(),
    );
  }

  /// Firestore に再生 URL が無い投稿向けに Apple Music（iTunes）の曲ページ URL を探す。
  Future<String?> lookupTrackUrl({
    required String artist,
    required String title,
  }) async {
    final hit = await _lookupBestHit(artist: artist, title: title);
    return hit == null ? null : _nonEmptyUrl(hit.listenUrl);
  }

  /// アプリ内再生用（iTunes の約30秒プレビュー URL）。
  Future<String?> lookupTrackPreviewUrl({
    required String artist,
    required String title,
  }) async {
    final hit = await _lookupBestHit(artist: artist, title: title);
    if (hit == null) return null;
    return _nonEmptyUrl(hit.previewUrl ?? '');
  }

  Future<String?> lookupArtworkUrl({
    required String artist,
    required String title,
  }) async {
    final hit = await _lookupBestHit(artist: artist, title: title);
    return _nonEmptyUrl(
      hit?.artworkUrl ?? '',
    )?.replaceFirst('100x100', '600x600');
  }

  Future<SongHit?> _lookupBestHit({
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
        return hit;
      }
    }
    for (final hit in hits) {
      if (_namesMatch(hit.artist, a)) {
        return hit;
      }
    }
    return hits.first;
  }

  Future<List<SongHit>> _fetchSongHits({
    required String term,
    required int limit,
    String? attribute,
  }) async {
    final params = <String, String>{
      'term': term,
      'entity': 'song',
      'limit': '$limit',
      'country': 'JP',
      'lang': 'ja_jp',
    };
    if (attribute != null) params['attribute'] = attribute;
    final uri = Uri.https('itunes.apple.com', '/search', params);
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('曲の検索に失敗しました');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = (body['results'] as List<dynamic>? ?? []);
    return results
        .map((raw) {
          final item = raw as Map<String, dynamic>;
          return SongHit(
            artist: (item['artistName'] as String?) ?? '',
            title: (item['trackName'] as String?) ?? '',
            listenUrl: (item['trackViewUrl'] as String?) ?? '',
            previewUrl: item['previewUrl'] as String?,
            artworkUrl: item['artworkUrl100'] as String?,
          );
        })
        .where((song) => song.artist.isNotEmpty && song.title.isNotEmpty)
        .toList();
  }

  static String _normalizeName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  static String _compactName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[\s.]'), '');

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

class _ArtistAndTitle {
  const _ArtistAndTitle(this.artist, this.title);

  final String artist;
  final String title;
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
