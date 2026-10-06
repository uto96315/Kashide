import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/song/song_search_service.dart';

/// 投稿に紐づく再生 URL（保存済み or Apple Music 検索）をメモリキャッシュ付きで解決する。
class ListenUrlResolver {
  ListenUrlResolver(this._search);

  final SongSearchService _search;
  final _cache = <String, String?>{};

  static String cacheKey(String artist, String singName) =>
      '${artist.trim()}|${singName.trim()}';

  Future<String?> resolve({
    required String storedUrl,
    required String artist,
    required String singName,
  }) async {
    final saved = storedUrl.trim();
    if (saved.isNotEmpty) return saved;

    final key = cacheKey(artist, singName);
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final url = await _search.lookupTrackUrl(artist: artist, title: singName);
      _cache[key] = url;
      return url;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }

  Future<String?> resolvePost(Post post) => resolve(
        storedUrl: post.youtubeLink,
        artist: post.artist,
        singName: post.singName,
      );
}
