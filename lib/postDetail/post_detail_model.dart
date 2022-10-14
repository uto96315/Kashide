

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import '../element/comment/comment_model.dart';

class PostDetailModel extends ChangeNotifier {
  PostDetailModel(id, commentButtontapped);

  var uid = FirebaseAuth.instance.currentUser?.uid;

  final commentController = TextEditingController();

  // 投稿関係
  String? postText;
  String? posterId;
  String? singName;
  String? singerName;
  List genreList = [];

  // 投稿者関係
  String? posterName;
  String? userIconUrl;

  // ユーザー関係
  String? userName;
  String? userImageUrl;

  // コメント関係
  String? comment;
  bool canComment = false;

  // UI関係
  bool counterTextVisible = false;  // コメント入力欄のカウント表示


  // 投稿の詳細取得
  Future getPost(String id) async{
    final doc = FirebaseFirestore.instance.collection("posts").doc(id);

    final snapshot = await doc.get();
    final data = snapshot.data();

    postText = data?["text"];
    posterId = data?["posterId"];
    singName = data?["singName"];
    singerName = data?["artist"];
    genreList = data?["genres"];

    await getPosterData(posterId ?? "");

    notifyListeners();
  }

  // 投稿者の取得
  Future getPosterData(String id) async{
    final doc = FirebaseFirestore.instance.collection("users").doc(id);

    final snapshot = await doc.get();
    final data = snapshot.data();

    posterName = data?["userName"] ?? "";
    userIconUrl = data?["iconUrl"] ?? "";
    notifyListeners();
  }

  // ユーザーの情報取得
  Future getUserData() async{
    final doc = FirebaseFirestore.instance.collection("users")
                  .doc(uid);
    final snapshot = await doc.get();
    userImageUrl = snapshot["iconUrl"];
    userName = snapshot["userName"];

    notifyListeners();
  }


  // コメント入力欄のカウント
  void showCount(String text) {
    if(text.isNotEmpty) {
      counterTextVisible = true;
    } else {
      counterTextVisible = false;
    }
    notifyListeners();
  }


  // コメントの可否判定
  void checkComment(String text) {
    if(text.isEmpty) {
      return;
    }
    canComment = true;
  }


  // コメントの投稿機能
  Future addComment(String postId) async{
    comment = commentController.text;
    final doc = FirebaseFirestore.instance
                  .collection("posts").doc(postId).collection("comments");

    await doc.add({
      "comment": comment,
      "createdAt": DateTime.now(),
      "posterId": uid
    });

    debugPrint("コメントを送信しました");

    notifyListeners();
  }
}
