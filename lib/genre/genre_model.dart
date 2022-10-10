import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;



class GenreModel extends ChangeNotifier {
  GenreModel(this.genre);
  String? genre;
  int? postCount;
  List<Post> genrePostsList = [];

  var uid = FirebaseAuth.instance.currentUser?.uid;

  // 投稿を取得する処理
  Future getGenrePosts(String genre) async{
    final doc = FirebaseFirestore.instance.collection("posts")
                  .where("genres", arrayContains: genre);
    final snapshot = await doc.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    genrePostsList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final doc = entry.value;
      return Post(
        doc["artist"],
        doc["singName"],
        doc["text"],
        doc["posterId"],
        doc["likedCount"],
        doc["genres"],
        "${userInfo[index][0]}",
        "${userInfo[index][1]}",
        createTimeMessage(doc["createdAt"].toDate()),
        doc.id,
      );
    }).toList();

    postCount = genrePostsList.length;

    debugPrint("読み込みました");
    notifyListeners();
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


  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }

  // 投稿を削除する処理
  // todo: 処理後にダイアログを表示する
  Future deletePosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id);

    genrePostsList.removeWhere((post) => post.id == id);

    await doc.delete();
    notifyListeners();
  }

  // 投稿を報告する処理
  // todo: 処理後にダイアログを表示する
  Future reportPosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("reportedPosts");

    await doc.add({
      "id": id,
      "reportedAt": DateTime.now(),
      "posterId": uid
    });
    notifyListeners();
  }
}