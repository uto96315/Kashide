import 'package:str_gram_beta/domain/post_domain.dart';
enum PostSearchMatch {
  lyrics,
  artist,
  songTitle,
  genre,
}

class ScoredSearchHit {
  ScoredSearchHit({
    required this.post,
    required this.score,
    required this.matches,
  });

  final Post post;
  final int score;
  final Set<PostSearchMatch> matches;
}

/// 投稿検索用の正規化・スコアリング。
class PostSearchMatcher {
  PostSearchMatcher({
    required this.query,
    this.itunesArtists = const {},
    this.itunesTitles = const {},
  });

  final String query;
  final Set<String> itunesArtists;
  final Set<String> itunesTitles;

  static String compact(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\s.\u3000・]'), '');
  }

  static String normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

  bool _containsFuzzy(String haystack, String needle) {
    if (needle.isEmpty || haystack.isEmpty) return false;
    if (normalize(haystack).contains(normalize(needle))) return true;
    return compact(haystack).contains(compact(needle));
  }

  ScoredSearchHit? scorePost(Post post) {
    final q = query.trim();
    if (q.isEmpty) return null;

    var score = 0;
    final matches = <PostSearchMatch>{};

    if (_containsFuzzy(post.text, q)) {
      score += 42;
      matches.add(PostSearchMatch.lyrics);
    }
    for (final seg in post.textSegments) {
      if (_containsFuzzy(seg, q)) {
        score += 38;
        matches.add(PostSearchMatch.lyrics);
        break;
      }
    }

    if (normalize(post.artist) == normalize(q) || compact(post.artist) == compact(q)) {
      score += 55;
      matches.add(PostSearchMatch.artist);
    } else if (_containsFuzzy(post.artist, q)) {
      score += 36;
      matches.add(PostSearchMatch.artist);
    }

    if (normalize(post.singName) == normalize(q) || compact(post.singName) == compact(q)) {
      score += 52;
      matches.add(PostSearchMatch.songTitle);
    } else if (_containsFuzzy(post.singName, q)) {
      score += 34;
      matches.add(PostSearchMatch.songTitle);
    }

    for (final g in post.genres) {
      final genre = g.toString();
      if (genre.isEmpty) continue;
      if (_containsFuzzy(genre, q) || normalize(genre) == normalize(q)) {
        score += 28;
        matches.add(PostSearchMatch.genre);
        break;
      }
    }

    for (final hint in itunesArtists) {
      if (hint.isEmpty) continue;
      if (_namesLoose(post.artist, hint)) {
        score += 32;
        matches.add(PostSearchMatch.artist);
        break;
      }
    }
    for (final hint in itunesTitles) {
      if (hint.isEmpty) continue;
      if (_namesLoose(post.singName, hint) || _containsFuzzy(post.singName, hint)) {
        score += 30;
        matches.add(PostSearchMatch.songTitle);
        break;
      }
      if (_containsFuzzy(post.text, hint)) {
        score += 22;
        matches.add(PostSearchMatch.lyrics);
      }
    }

  if (matches.isEmpty || score < 22) return null;
    return ScoredSearchHit(post: post, score: score, matches: matches);
  }

  bool _namesLoose(String a, String b) {
    final ca = compact(a);
    final cb = compact(b);
    if (ca.isEmpty || cb.isEmpty) return false;
    return ca == cb || ca.contains(cb) || cb.contains(ca);
  }

  static List<String> highlightNeedles(String query, {Set<String> extra = const {}}) {
    final needles = <String>{query.trim()};
    for (final part in query.split(RegExp(r'\s+'))) {
      if (part.trim().length >= 2) needles.add(part.trim());
    }
    needles.addAll(extra.where((e) => e.trim().length >= 2));
    return needles
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
  }
}
