import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import '../domain/post_domain.dart';



class MyModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;
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
  Future getUserPosts() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore
        .instance
        .collection("posts")
        .where("posterId", isEqualTo: uid);
        // .orderBy("createdAt", descending: true);
    final snapshot = await doc.get();
    userPostsList = snapshot.docs.map((doc) =>
        Post(
            doc["artist"],
            doc["singName"],
            doc["text"],
            doc["posterId"],
            doc["likeCount"],
            doc["tags"],
            userName ?? "",
            userImageURL ?? "",
            createTimeMessage(doc["createdAt"].toDate())
        )
    ).toList();
  }

  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }
}
