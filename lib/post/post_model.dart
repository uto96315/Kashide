import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class PostModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;

  final lyricsController = TextEditingController();
  final singerNameController = TextEditingController();
  final singNameController = TextEditingController();

  String? lyrics;
  String? singerName;
  String? singName;
  String? userName;

  // 歌詞をセットする処理
  void setLyrics(String lyrics) {
    this.lyrics = lyrics;
    notifyListeners();
  }

  // 歌手名をセットする処理
  void setSinger(String singer) {
    singerName = singer;
    notifyListeners();
  }

  // 曲名をセットする処理
  void setSing(String sing) {
    singName = sing;
    notifyListeners();
  }

  // 投稿する処理
  Future post() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("posts");
    await getUserData();

    await doc.add({
      "artist": singerName ?? "不明",
      "likeCount": 0,
      "posterId": uid,
      "posterName": userName ?? "不明",
      "tags": "null",
      "text": lyrics,
      "singName": singName ?? "不明"
    });
  }

  // ユーザー情報を取得する処理
  Future getUserData() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    var get = await doc.get();
    var data = get?.data();

    this.userName = data?["userName"];
  }
}