

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeago/timeago.dart' as timeAgo;

import '../domain/comment_domain.dart';

class PostDetailModel extends ChangeNotifier {
  PostDetailModel(id, commentButtonTapped);

  var uid = FirebaseAuth.instance.currentUser?.uid;

  final commentController = TextEditingController();

  // 投稿関係
  String? postText;
  String? posterId;
  String? singName;
  String? singerName;
  List genreList = [];
  int? likedCount;
  String? explanation;
  String? youtubeLink;

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
    likedCount = data?["likedCount"];
    explanation = data?["explanation"];
    youtubeLink = data?["youtubeLink"] ?? "";

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
  Future getUserData(String uid) async{
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    userImageUrl = snapshot["iconUrl"];
    userName = snapshot["userName"];

    notifyListeners();
  }

  // ユーザー情報を取得する関数 // todo: 上と一つにする
  Future getUserDataF(String uid) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final userName = data?["userName"];
    final userImageUrl = data?["iconUrl"];
    notifyListeners();
    return [userName, userImageUrl];
  }


  // コメント入力欄のカウント
  void showCount(String text) {
    counterTextVisible = text.isNotEmpty;
    notifyListeners();
  }


  // コメントの可否判定
  void checkComment(String text) {
    canComment = text.isNotEmpty;
    notifyListeners();
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
    canComment = false;
    await getComments(postId);
    notifyListeners();
  }





  //---------------------

  List<CommentDomain> commentsList = [];

  // コメントの取得
  Future getComments(String postId) async {
    final collection = FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .orderBy("createdAt");

    final snapshot = await collection.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserDataF(doc["posterId"])).toList());

    commentsList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final doc = entry.value;

      return CommentDomain(
        doc.id,
        doc["comment"],
        createTimeMessage(doc["createdAt"].toDate()),
        doc["posterId"],
        "${userInfo[index][0]}",
        "${userInfo[index][1]}",
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

  // コメントの削除機能
  Future deleteComment(String postId, String commentId) async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("comments")
        .doc(commentId);

    await doc.delete();
    debugPrint("削除しました");

    await getComments(postId);
    notifyListeners();
  }

  // コメントの報告機能
  Future reportComment(String postId, String commentId, String commentText) async{
    final doc = FirebaseFirestore.instance
        .collection("reportedComments");

    await doc.add({
      "postId": postId,
      "commentId": commentId,
      "commentText": commentText,
      "reportedAt": DateTime.now(),
    });
    debugPrint("報告しました");
    notifyListeners();
  }
}
