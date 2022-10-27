import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';


class PostModel extends ChangeNotifier {
  PostModel(this.defaultGenres){
    defaultGenres = defaultGenres;
  }

  var user = FirebaseAuth.instance.currentUser;

  final lyricsController = TextEditingController();
  final singerNameController = TextEditingController();
  final singNameController = TextEditingController();
  final genreController = TextEditingController();
  final explanationController = TextEditingController();
  final youtubeLinkController = TextEditingController();

  String? defaultGenres;
  String? explanation;
  String? lyrics;
  String? singerName;
  String? singName;
  String? userName;
  List<String> genres = [];
  bool canPush = false;
  bool genreMaxLength = true; // ジャンルが三個に達したらtrueにする
  String? youtubeLink;


  // 理由をセット
  void setExplanation(String explanationText) {
    explanation = explanationText;
    notifyListeners();
  }

  // 歌詞をセットする処理
  void setLyrics(String lyrics) {
    this.lyrics = lyrics;
    if(lyrics.isNotEmpty) {
      canPush = true;
    } else {
      canPush = false;
    }
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

  // youtubeのリンクセット
  void setYoutubeLink(String text) {
    youtubeLink = text;
    notifyListeners();
  }


  //　ジャンルから飛んできたのであればセット
  void setDefaultGenre(String? propGenre) {
    if(propGenre != null){
      genres.add(propGenre);
      debugPrint("ジャンルの初期値をセットしました");
    }
  }

  // ジャンルを付与する処理
  void setGenre(String genre) {
    if(genres.contains(genre)) {
      // genres.remove(genre);
      return;
    } else {
      genres.add(genre);
      if(genres.length == 3) {
        genreMaxLength = false;
      }
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
    if(genreMaxLength == false) {
      genreMaxLength = true;
    }

    notifyListeners();
  }

  // 投稿する処理
  Future post() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("posts");

    await doc.add({
      "explanation": explanation ?? "",
      "artist": singerName ?? "不明",
      "likedCount": 0,
      "posterId": uid,
      "genres": genres,  // todo: ここは後から変更する
      "text": lyrics,
      "singName": singName ?? "不明",
      "createdAt": DateTime.now(),
      "youtubeLink": youtubeLink ?? "",
    });
  }
}