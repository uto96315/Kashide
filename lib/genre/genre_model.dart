import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';
import 'package:str_gram_beta/post/post_view_service.dart';
import 'package:timeago/timeago.dart' as timeAgo;
import 'package:url_launcher/url_launcher.dart';


class GenreModel extends ChangeNotifier {
  GenreModel(this.genre, this.condition);

  final addPlaylistController = TextEditingController();

  String? genre;
  String? condition;
  int? postCount;
  List<Post> genrePostsList = [];
  List playList = [];
  String? newPlaylistName;

  var uid = FirebaseAuth.instance.currentUser?.uid;

  Future<void> refreshViewCountForPost(String postId) async {
    await refreshViewCountInList(genrePostsList, postId);
    notifyListeners();
  }

  String? profileUserName;
  String? profileImageUrl;
  String? profileIntroduction;

  Future<void> loadPosterProfile(String posterId) async {
    if (condition != 'poster') return;
    final snapshot = await FirebaseFirestore.instance.collection('users').doc(posterId).get();
    final data = snapshot.data();
    profileUserName = data?['userName'] as String?;
    profileImageUrl = data?['iconUrl'] as String?;
    profileIntroduction = data?['introduction'] as String?;
    notifyListeners();
  }

  /// users ドキュメントに icon が無い場合、投稿から拾う。
  String? get displayProfileImageUrl {
    if (profileImageUrl != null && profileImageUrl!.isNotEmpty && profileImageUrl != 'null') {
      return profileImageUrl;
    }
    for (final post in genrePostsList) {
      if (post.userImageUrl.isNotEmpty && post.userImageUrl != 'null') {
        return post.userImageUrl;
      }
    }
    return null;
  }

  // 投稿を取得する処理
  Future getGenrePosts(String genre) async{

    Query<Map<String, dynamic>> doc;

    if(condition == "genre") {
      doc = FirebaseFirestore.instance.collection("posts")
          .where("genres", arrayContains: genre);
    } else if( condition == "artist") {
      doc = FirebaseFirestore.instance.collection("posts")
          .where("artist", isEqualTo: genre);
    } else if( condition == "singName") {
      doc = FirebaseFirestore.instance.collection("posts")
          .where("singName", isEqualTo: genre);
    } else if (condition == "poster") {
      doc = FirebaseFirestore.instance.collection("posts")
          .where("posterId", isEqualTo: genre);
    } else { return; }

    final snapshot = await doc.get();

    // ユーザー情報の取得
    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    final commentCount = await Future.wait(
        snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );

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
        commentCount[index],
        doc["explanation"],
        doc["youtubeLink"],
        viewCount: viewCountFromFirestore(doc.data()),
        textSegments: lyricSegmentsFromFirestore(doc.data()),
      );
    }).toList();

    postCount = genrePostsList.length;

    debugPrint("読み込みました");
    notifyListeners();
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

  // コメント数の取得
  Future getCommentCount(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id).collection("comments");
    final snapshot = await doc.get();
    final count = snapshot.docs.length;

    return count;
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

  // Youtubeアプリを開く処理
  Future launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
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
}