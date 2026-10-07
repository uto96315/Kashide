import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import '../../domain/post_domain.dart';
import '../../post/post_lyrics.dart';
import '../../post/post_view_service.dart';

class LyricsSearchModel extends ChangeNotifier {
  LyricsSearchModel(this.searchWord);

  String? searchWord; // 検索ワード

  List<Post> resultList = []; // 一旦全部取得する
  List<Post> lyricsResultList = []; // ジャンル検索に引っかかった投稿
  int lyricsResultCount = 0; // ジャンル結果の総数
  bool isLoading = true;

  // ジャンルから探す処理=========================
  Future searchFromLyrics(String searchWord) async {
    try {
    final snapshot = await FirebaseFirestore.instance
        .collection("posts")
        .orderBy("createdAt", descending: true)
        .limit(100)
        .get();

    // ユーザー情報の取得
    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    // コメント数の取得
    final commentCount = await Future.wait(
        snapshot.docs.map((doc) => getCommentCount(doc.id)).toList());

    // ここで合体
    resultList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final postData = entry.value;

      return Post(
        postData["artist"],
        postData["singName"],
        postData["text"],
        postData["posterId"],
        postData["likedCount"],
        postData["genres"],
        "${userInfo[index][0]}",
        "${userInfo[index][1]}",
        createTimeMessage(postData["createdAt"].toDate()),
        postData.id,
        commentCount[index] ?? 0,
        postData["explanation"],
        postData["youtubeLink"],
        viewCount: viewCountFromFirestore(postData.data()),
        textSegments: lyricSegmentsFromFirestore(postData.data()),
      );
    }).toList();

    lyricsResultList = resultList.where
      ((element) => element.text.contains(searchWord)).toList();
    
    lyricsResultCount = lyricsResultList.length;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

// ジャンルから探す処理=========================

  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }

  // ユーザー情報を取得する関数
  Future getUserData(String uid) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final userName = data?["userName"];
    final userImageUrl = data?["iconUrl"];
    notifyListeners();
    return [userName, userImageUrl];
  }

  // コメント数の取得
  Future getCommentCount(String id) async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        .doc(id)
        .collection("comments");
    final snapshot = await doc.get();
    final count = snapshot.docs.length;

    return count;
  }
}
