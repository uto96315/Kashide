import 'package:cloud_firestore/cloud_firestore.dart';

/// 投稿画面と同じ Firestore マスタ。取得失敗時はこの一覧。
const kFallbackDefaultGenres = [
  '恋愛ソング',
  '懐メロ',
  'JPOP',
  '男性目線',
  '女性目線',
  'LGBTQ',
  '洋楽',
  '失恋ソング',
  '人生',
  'ロック',
  'ジャニーズ',
  '元気になれる曲',
  'R&B ソウル',
  'アイドル',
  '青春',
  '勇気',
  'ペット',
];

Future<List<String>> fetchDefaultGenres() async {
  try {
    final snapshot = await FirebaseFirestore.instance.collection('genres').doc('defaultGenres').get();
    final raw = snapshot.data()?['genres'];
    if (raw is List) {
      return raw.whereType<String>().where((g) => g.isNotEmpty).toList();
    }
  } catch (_) {}
  return kFallbackDefaultGenres;
}
