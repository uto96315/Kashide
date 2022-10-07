import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class PostModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;

  final lyricsController = TextEditingController();
  final singerNameController = TextEditingController();
  final singNameController = TextEditingController();
  final genreController = TextEditingController();

  String? lyrics;
  String? singerName;
  String? singName;
  String? userName;
  List<String> genres = [];

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

  // ジャンルを付与する処理
  void setGenre(String genre) {
    if(genres.contains(genre)) {
      // genres.remove(genre);
      return;
    } else {
      genres.add(genre);
    }

    // 一度テキストフィールド内をクリアする
    genreController.clear();

    // todo: この後再度フォーカスさせたい

    notifyListeners();
  }

  // ジャンルを削除する機能
  void deleteGenre(String genre) {
    if(genres.contains(genre)) {
      genres.remove(genre);
    }
    notifyListeners();
  }

  // 投稿する処理
  Future post() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("posts");

    await doc.add({
      "artist": singerName ?? "不明",
      "likeCount": 0,
      "posterId": uid,
      "genres": genres,  // todo: ここは後から変更する
      "text": lyrics,
      "singName": singName ?? "不明",
      "createdAt": DateTime.now()
    });
  }
}