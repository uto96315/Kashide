import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

import '../domain/post_domain.dart';

class TimelineModel extends ChangeNotifier {
  var user = FirebaseAuth.instance.currentUser;
  List<Posts> postsList = []; // 投稿全体を格納する

  // ユーザー情報を取得する関数
  Future getUserData() async {
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    var userName = snapshot["userName"];
    return userName;
  }

  // 投稿を取得する処理
  Future getPosts() async {
    final doc = FirebaseFirestore.instance.collection("posts");
    // .orderBy("createdAt", descending: true)
    final snapshot = await doc.get();
    final posts = snapshot.docs
        .map((doc) => Posts(doc["artist"], doc["singName"], doc["text"],
            doc["posterId"], doc["likeCount"], doc["tags"]))
        .toList();

    postsList = posts;
    print("投稿を読み込みました");
    notifyListeners();
  }
}
