import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import '../domain/post_domain.dart';
import '../post/post_lyrics.dart';
import '../post/post_view_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';


class MyModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;
  var uid = FirebaseAuth.instance.currentUser?.uid;
  var sidebarKey = GlobalKey<ScaffoldState>();
  final deviceInfoPlugin = DeviceInfoPlugin();

  String? userName;
  String? userIntroduction;
  String? userAge;
  String? userGender;
  String? userImageURL;
  List<dynamic>? userFavorite;
  List<Post> userPostsList = [];
  bool postsReady = false;
  int likedPostsCount = 0;
  bool likedCountReady = false;
  String? iosVersion;// 現在のiosバージョン
  String? androidVersion; // 現在のandroidバージョン
  String? latestIosVersion; // 最新のiosバージョン
  String? latestAndroidVersion; // 最新のandroidバージョン

  void bindCurrentAuthUser() {
    user = FirebaseAuth.instance.currentUser;
    uid = user?.uid;
  }

  // ユーザー情報の取得
  Future getUserData() async{
    bindCurrentAuthUser();
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

  // バージョンを取得する関数
  Future getVersions()async{
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version; // 現在のバージョンを取得

    if(Platform.isAndroid) {
      print("OSはandroidでバージョンは${version}です");
      androidVersion = version;
    }
    else {
      print("OSはiOSでバージョンは${version}です");
      iosVersion = version;
    }
  }

  Future<void> loadLikedCount() async {
    final uid = user?.uid;
    if (uid == null) {
      likedPostsCount = 0;
      likedCountReady = true;
      notifyListeners();
      return;
    }
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('likePost').get();
    likedPostsCount = snap.docs.length;
    likedCountReady = true;
    notifyListeners();
  }

  // ユーザーの投稿を取得する処理
  // todo: ここをasMapに変換する
  Future getUserPosts() async{
    bindCurrentAuthUser();
    var uid = user?.uid;
    final doc = FirebaseFirestore
        .instance
        .collection("posts")
        .where("posterId", isEqualTo: uid)
        .orderBy("createdAt", descending: true);

    final snapshot = await doc.get();
    final commentCounts = await Future.wait(
      snapshot.docs.map((doc) => getCommentCount(doc.id)),
    );
    userPostsList = snapshot.docs.asMap().entries.map((entry) {
      final doc = entry.value;
      return Post(
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
            commentCounts[entry.key],
            doc["explanation"],
            doc["youtubeLink"],
            viewCount: viewCountFromFirestore(doc.data()),
            textSegments: lyricSegmentsFromFirestore(doc.data()),
        );
    }).toList();
    postsReady = true;
    notifyListeners();
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
  Future deletePosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id);

    await doc.delete();

    await getUserPosts();
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

  // レビューを促す処理
  void requestReview() {
    final review = InAppReview.instance;
    review.isAvailable().then((available) {
      if (available) {
        review.requestReview();
      }
    });
    notifyListeners();
  }
}
