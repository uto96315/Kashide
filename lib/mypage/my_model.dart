import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import '../domain/post_domain.dart';



class MyModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;
  var uid = FirebaseAuth.instance.currentUser?.uid;
  var sidebarKey = GlobalKey<ScaffoldState>();

  String? userName;
  String? userIntroduction;
  String? userAge;
  String? userGender;
  String? userImageURL;
  List<dynamic>? userFavorite;
  List<Post> userPostsList = []; // 投稿全体を格納する

  // ユーザー情報の取得
  Future getUserData() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final get = await doc.get();
    final data = get.data();

    userName = data?["userName"];
    userIntroduction = data?["introduction"];
    userAge = data?["age"];
    userGender = data?["gender"];
    userFavorite = data?["favorite"];
    userImageURL = data?["iconUrl"];

    notifyListeners();
  }


  //　ログアウトさせる処理
  Future logOut() async{
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  // ユーザーの投稿を取得する処理
  // todo: ここをasMapに変換する
  Future getUserPosts() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore
        .instance
        .collection("posts")
        .where("posterId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    final snapshot = await doc.get();
    userPostsList = snapshot.docs.map((doc) =>
        Post(
            doc["artist"],
            doc["singName"],
            doc["text"],
            doc["posterId"],
            doc["likedCount"],
            doc["genres"],
            userName ?? "",
            userImageURL ?? "",
            createTimeMessage(doc["createdAt"].toDate()),
            doc.id,
            0,
            doc["explanation"],
        )
    ).toList();
  }

  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }


  // コメント数の取得
  Future getCommentCount(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id).collection("comments");
    final snapshot = await doc.get();
    final count = snapshot.docs.length;

    return count;
  }


  // 投稿を削除する処理
  // todo: 処理後にダイアログを表示する
  Future deletePosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id);

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
