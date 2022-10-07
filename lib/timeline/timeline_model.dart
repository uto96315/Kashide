import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/domain/user_domain.dart';
import '../domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class TimelineModel extends ChangeNotifier {
  var user = FirebaseAuth.instance.currentUser;
  List<Post> postsList = []; // 投稿全体を格納する

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

  // 投稿を取得する処理
  Future getPosts() async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        .orderBy("createdAt", descending: true);
    final snapshot = await doc.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());


    postsList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final doc = entry.value;
      return Post(
          doc["artist"],
          doc["singName"],
          doc["text"],
          doc["posterId"],
          doc["likeCount"],
          [""],
          "${userInfo[index][0]}",
          "${userInfo[index][1]}",
          createTimeMessage(doc["createdAt"].toDate())
          );
    }).toList();
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }
}
