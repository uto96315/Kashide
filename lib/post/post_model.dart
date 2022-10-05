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
    final doc = FirebaseFirestore.instance.collection("posts").doc(uid);

    await doc.set({
      "artist": singerName ?? "不明",
      "likeCount": 0,
      "posterId": uid,
      "tags": "null",
      "text": lyrics,
      "singName": singName ?? "不明"
    });
  }
}