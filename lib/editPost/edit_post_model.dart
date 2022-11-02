

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class EditPostModel extends ChangeNotifier {
  EditPostModel(
      this.defaultText,
      this.defaultSingerName,
      this.defaultSingName,
      this.defaultGenreList,
      this.postId,
      this.defaultExplanation,
      this.youtubeLink
      )
  {
    postTextController.text = defaultText ?? "";
    postSingerController.text = defaultSingerName ?? "";
    postSingNameController.text = defaultSingName ?? "";
    defaultGenreList = defaultGenreList ?? [];
    postId = postId;
    explanationController.text = defaultExplanation ?? "";
    youtubeLinkController.text = youtubeLink ?? "";
  }

  var uid = FirebaseAuth.instance.currentUser?.uid;

  final postTextController = TextEditingController();
  final postSingerController = TextEditingController();
  final postSingNameController = TextEditingController();
  final genreController = TextEditingController();
  final explanationController = TextEditingController();
  final youtubeLinkController = TextEditingController();

  String? postId;
  String? defaultExplanation;
  String? defaultText;
  String? defaultSingerName;
  String? defaultSingName;
  List defaultGenreList = [];
  bool genreMaxLength = true; // 三つ以下
  bool canPush = true;
  String? youtubeLink;

  // 理由をセット
  void setExplanation(String explanationText) {
    defaultExplanation = explanationText;
    notifyListeners();
  }

  // 歌詞をセットする処理
  void setLyrics(String text) {
    if(text.isNotEmpty) {
      defaultText = text;
      canPush = true;
    }
    notifyListeners();
  }


  // 歌手をセットする関数
  void setSinger(String singer) {
    if(singer.isNotEmpty) {
      defaultSingerName = singer;
    }
    notifyListeners();
  }


  // 曲名をセットする処理
  void setSing(String sing) {
    if(sing!.isNotEmpty) {
      defaultSingName = sing;
    }
    notifyListeners();
  }

  // youtubeのリンクをセット
  void setYoutubeLink(String text){
    youtubeLink = text;
    notifyListeners();
  }


  // ジャンルを付与する処理
  void setGenre(String genre) {
    if(defaultGenreList.contains(genre)) {
      // genres.remove(genre);
      return;
    } else {
      defaultGenreList.add(genre);
      if(defaultGenreList.length == 3) {
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
    if(defaultGenreList.contains(genre)) {
      defaultGenreList.remove(genre);
    }
    if(genreMaxLength == false) {
      genreMaxLength = true;
    }

    notifyListeners();
  }



  // 投稿をアップデートする関数
  Future updatePost() async{
    final doc = FirebaseFirestore.instance.collection("posts").doc(postId);

    await doc.update({
      "artist": defaultSingerName ?? "不明",
      "likedCount": 0,
      "posterId": uid,
      "genres": defaultGenreList,  // todo: ここは後から変更する
      "text": defaultText,
      "singName": defaultSingName ?? "不明",
      "explanation": defaultExplanation ?? "",
      "updatedAt": DateTime.now(),
      "youtubeLink": youtubeLink ?? "",
    });

    notifyListeners();
  }
}