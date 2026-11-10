import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';
import 'package:str_gram_beta/search/post_search_matcher.dart';
import 'package:str_gram_beta/song/song_search_service.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class UnifiedSearchModel extends ChangeNotifier {
  UnifiedSearchModel(this.searchWord, this._songSearch);

  final String searchWord;
  final SongSearchService _songSearch;

  var isLoading = true;
  String? errorMessage;
  final List<ScoredSearchHit> hits = [];
  var itunesHintCount = 0;

  Future<void> search() async {
    final q = searchWord.trim();
    if (q.isEmpty) {
      isLoading = false;
      notifyListeners();
      return;
    }

    isLoading = true;
    errorMessage = null;
    hits.clear();
    itunesHintCount = 0;
    notifyListeners();

    try {
      final itunes = await _songSearch.searchSongs(q);
      final artists = itunes.map((e) => e.artist).where((s) => s.isNotEmpty).toSet();
      final titles = itunes.map((e) => e.title).where((s) => s.isNotEmpty).toSet();
      itunesHintCount = artists.length + titles.length;

      final docMap = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};

      Future<void> mergeQuery(Query<Map<String, dynamic>> query) async {
        final snap = await query.get();
        for (final doc in snap.docs) {
          docMap[doc.id] = doc;
        }
      }

      final lowerQ = q.toLowerCase();

      await Future.wait([
        mergeQuery(
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('createdAt', descending: true)
              .limit(450),
        ),
        mergeQuery(
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('artist')
              .startAt([q])
              .endAt(['$q\uf8ff'])
              .limit(60),
        ),
        mergeQuery(
          FirebaseFirestore.instance
              .collection('posts')
              .orderBy('singName')
              .startAt([q])
              .endAt(['$q\uf8ff'])
              .limit(60),
        ),
        mergeQuery(
          FirebaseFirestore.instance
              .collection('posts')
              .where('genres', arrayContains: q)
              .limit(40),
        ),
        if (lowerQ != q)
          mergeQuery(
            FirebaseFirestore.instance
                .collection('posts')
                .orderBy('artist')
                .startAt([lowerQ])
                .endAt(['$lowerQ\uf8ff'])
                .limit(40),
          ),
      ]);

      final docs = docMap.values.toList(growable: false);
      final userInfo = await Future.wait(
        docs.map((doc) => _getUserData(doc['posterId'].toString())),
      );
      final commentCounts = await Future.wait(
        docs.map((doc) => _commentCount(doc.id)),
      );

      final matcher = PostSearchMatcher(
        query: q,
        itunesArtists: artists,
        itunesTitles: titles,
      );

      final scored = <String, ScoredSearchHit>{};
      for (var i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final post = Post(
          doc['artist']?.toString() ?? '',
          doc['singName']?.toString() ?? '',
          doc['text']?.toString() ?? '',
          doc['posterId'].toString(),
          (doc['likedCount'] as num?)?.toInt() ?? 0,
          List<dynamic>.from(doc['genres'] ?? const []),
          '${userInfo[i][0]}',
          '${userInfo[i][1]}',
          _formatTime(doc['createdAt']),
          doc.id,
          commentCounts[i],
          doc['explanation']?.toString() ?? '',
          doc['youtubeLink']?.toString() ?? '',
          textSegments: lyricSegmentsFromFirestore(doc.data()),
        );
        final hit = matcher.scorePost(post);
        if (hit == null) continue;
        final prev = scored[post.id];
        if (prev == null || hit.score > prev.score) {
          scored[post.id] = hit;
        }
      }

      hits
        ..clear()
        ..addAll(scored.values)
        ..sort((a, b) => b.score.compareTo(a.score));
    } catch (e, st) {
      debugPrint('Unified search failed: $e\n$st');
      errorMessage = '検索中に問題が発生しました';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<List<String>> _getUserData(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snap.data();
    return [data?['userName']?.toString() ?? '', data?['iconUrl']?.toString() ?? ''];
  }

  Future<int> _commentCount(String postId) async {
    final snap = await FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .get();
    return snap.docs.length;
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt is! Timestamp) return '';
    return timeAgo.format(createdAt.toDate(), locale: 'ja');
  }
}
