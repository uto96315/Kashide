import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/domain/comment_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class CommentModel extends ChangeNotifier {
  CommentModel(id);

  var uid = FirebaseAuth.instance.currentUser?.uid;
  List<CommentDomain> commentsList = [];


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


  Future getComments(String postId) async {
    final collection = FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .orderBy("createdAt");

    final snapshot = await collection.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    commentsList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final doc = entry.value;

      return CommentDomain(
          doc.id,
          doc["comment"],
          createTimeMessage(doc["createdAt"].toDate()),
          "${userInfo[index][0]}",
          "${userInfo[index][1]}"
      );
    }).toList();

    notifyListeners();
  }


  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }
}
