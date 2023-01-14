import 'package:app_review/app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/domain/user_domain.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class TimelineModel extends ChangeNotifier {

  final addPlaylistController = TextEditingController();

  var user = FirebaseAuth.instance.currentUser;
  var uid = FirebaseAuth.instance.currentUser?.uid;
  List<Post> postsList = []; // 投稿全体を格納する
  List playList = [];
  List blockedUsers = [];
  String? newPlaylistName;

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

  // プレイリストを取得する関数
  Future getPlayListData()async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid).collection("playlists");
    final snapshot = await doc.get();
    playList = snapshot.docs.asMap().entries.map((entry){
      return {
        "id": entry.value.id,
        "playlistName": entry.value["playlistName"],
      };
    }).toList();
    notifyListeners();
  }

  // 投稿を取得する処理
  Future getPosts() async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        // .where("posterId", whereNotIn: blockedUsers)
        .orderBy("createdAt", descending: true);
    final snapshot = await doc.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    final commentCount = await Future.wait(
      snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );


    postsList = snapshot.docs.asMap().entries.map((entry) {
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
          commentCount[index],
          doc["explanation"] ?? "",
          doc["youtubeLink"] ?? ""
      );
    }).toList();
    postsList.removeWhere((post) => blockedUsers.contains(post.posterId));
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  // 最初に１０件を取得する
  Future getFirstPostData()async{
    await getBlockedUsers();
    final doc = FirebaseFirestore.instance
        .collection("posts")
        // .where("posterId", whereNotIn: blockedUsers)
        .orderBy("createdAt", descending: true).limit(10);

    final snapshot = await doc.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    final commentCount = await Future.wait(
        snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );


    postsList = snapshot.docs.asMap().entries.map((entry) {
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
          commentCount[index],
          doc["explanation"] ?? "",
          doc["youtubeLink"] ?? ""
      );
    }).toList();

    postsList.removeWhere((post) => blockedUsers.contains(post.posterId));
    debugPrint("投稿を読み込みました");
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
  // todo: 処理後にダイアログを表示する
  Future deletePosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id);

    postsList.removeWhere((post) => post.id == id);

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

  // Youtubeアプリを開く処理
  Future launchURL(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(
            url,
            forceSafariVC: false,
        );
      }
    } catch(e) {
      print(e.toString());
    }
  }

  // プレイリストに追加する処理
  Future addToPlaylist(String playlistId, String artist, String songName, String youtubeLink, String postId)async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid).collection("playlists")
        .doc(playlistId).collection("songs");

    try {
      await doc.add({
        "singName": songName,
        "artist": artist,
        "youtubeUrl": youtubeLink,
        "postId": postId,
        "addAt": DateTime.now(),
      });
      print("プレイリストに追加しました");
    } catch(e) {
      print(e.toString());
    }
    notifyListeners();
  }

  // 新しいプレイリストの文字列
  void setNewName( String text) {
    newPlaylistName = text;
    notifyListeners();
  }

  // プレイリストを追加する
  Future addNewPlaylist()async{
    newPlaylistName = addPlaylistController.text;
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists");
    await doc.add({
      "createdAt": DateTime.now(),
      "playlistName": newPlaylistName,
    });
    await getPlayListData();
    notifyListeners();
  }

  // ブロック処理
  Future blockUser(String posterId) async{
    final doc = FirebaseFirestore.instance.collection("users").doc(uid).collection("blockList");
    final targetUserDoc = FirebaseFirestore.instance.collection("users").doc(posterId);
    final blockedUserData = await targetUserDoc.get();

    await doc.add({
      "id": posterId,
      "blockedAt": DateTime.now(),
      "blockedUserName": blockedUserData["userName"],  // ここでブロックしたユーザーの名前
    });
    print(blockedUsers);
    notifyListeners();
  }

  // ブロックされているユーザーの取得
  Future getBlockedUsers() async{
    final doc = FirebaseFirestore.instance.collection("users").doc(uid).collection("blockList");
    final snapshot = await doc.get();
    blockedUsers = snapshot.docs.asMap().entries.map((blockedUser){
      return blockedUser.value["id"];
    }).toList();
    print(blockedUsers);
    notifyListeners();
  }

  // レビューを促す処理
  void requestReview() {
    AppReview.isRequestReviewAvailable.then((value){
      print(value);
      AppReview.requestReview.then((onValue) {
        print(onValue);
      });
    });
    notifyListeners();
  }
}
