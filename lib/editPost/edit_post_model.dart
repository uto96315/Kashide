

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:str_gram_beta/post/post_validation.dart';
import 'package:str_gram_beta/song/song_quote.dart';

class EditPostModel extends ChangeNotifier {
  EditPostModel(
      this.defaultLyrics,
      this.defaultSingerName,
      this.defaultSingName,
      this.selectedGenreList,
      this.postId,
      this.defaultExplanation,
      this.youtubeLink
      )
  {
    postLyricsController.text = defaultLyrics ?? "";
    postSingerController.text = defaultSingerName ?? "";
    postSingNameController.text = defaultSingName ?? "";
    selectedGenreList = selectedGenreList ?? [];
    postId = postId;
    explanationController.text = defaultExplanation ?? "";
    youtubeLinkController.text = youtubeLink ?? "";
  }

  var uid = FirebaseAuth.instance.currentUser?.uid;

  final postLyricsController = TextEditingController();
  final postSingerController = TextEditingController();
  final postSingNameController = TextEditingController();
  final genreController = TextEditingController();
  final explanationController = TextEditingController();
  final youtubeLinkController = TextEditingController();

  String? postId;
  String? defaultExplanation;
  String? defaultLyrics;
  String? defaultSingerName;
  String? defaultSingName;
  List selectedGenreList = []; // 選択されているジャンルの一覧
  List<String> defaultGenresList = [
    "恋愛ソング",
    "懐メロ",
    "JPOP",
    "男性目線",
    "女性目線",
    "LGBTQ",
    "洋楽",
    "失恋ソング",
    "人生",
    "ロック",
    "ジャニーズ",
    "元気になれる曲",
    "R&B ソウル",
    "アイドル",
    "青春",
    "勇気",
  ];
  bool genreMaxLength = true; // 三つ以下
  bool canPush = true;
  String? youtubeLink;

  // firestoreからジャンルを取得する
  Future getDefaultGenres()async{
    final doc = FirebaseFirestore.instance.collection("genres").doc("defaultGenres");
    final snapshot = await doc.get();
    defaultGenresList = snapshot.data()?["genres"].cast<String>();
    notifyListeners();
  }

  // 理由をセット
  void setExplanation(String explanationText) {
    defaultExplanation = explanationText;
    notifyListeners();
  }

  void applyQuote(SongQuote quote) {
    defaultSingerName = quote.artist;
    defaultSingName = quote.title;
    defaultLyrics = quote.lyrics;
    youtubeLink = quote.listenUrl;
    postSingerController.text = quote.artist;
    postSingNameController.text = quote.title;
    postLyricsController.text = quote.lyrics;
    youtubeLinkController.text = quote.listenUrl;
    _refreshCanPush();
    notifyListeners();
  }

  String? validationMessage() {
    return validatePostForm(
      singerName: defaultSingerName ?? postSingerController.text,
      singName: defaultSingName ?? postSingNameController.text,
      lyrics: defaultLyrics ?? postLyricsController.text,
      explanationLength: explanationController.text.length,
      lyricsMinLength: 0,
    );
  }

  void _refreshCanPush() {
    canPush = validationMessage() == null;
  }

  // 歌詞をセットする処理
  void setLyrics(String text) {
    defaultLyrics = text;
    _refreshCanPush();
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
    print(selectedGenreList.length);

    if(selectedGenreList.length >= 3) {
      return;
    }
    if(selectedGenreList.contains(genre)) {
      return;
    } else {
      if(!defaultGenresList.contains(genre)){
        defaultGenresList.add(genre);
      }
      selectedGenreList.add(genre);
      if(selectedGenreList.length == 3) {
        genreMaxLength = false;
      }
    }
    // 一度テキストフィールド内をクリアする
    genreController.clear();
    notifyListeners();
  }


  // ジャンルを削除する機能
  void deleteGenre(String genre) {
    if(selectedGenreList.contains(genre)) {
      selectedGenreList.remove(genre);
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
      "genres": selectedGenreList,  // todo: ここは後から変更する
      "text": defaultLyrics,
      "singName": defaultSingName ?? "不明",
      "explanation": defaultExplanation ?? "",
      "createdAt": DateTime.now(),
      "youtubeLink": youtubeLink ?? "",
    });

    notifyListeners();
  }

  // ペーストする関数
  void pasteText(controller) async{
    var data = await Clipboard.getData(Clipboard.kTextPlain);
    controller.text = data?.text.toString() ?? "";
    if (data != null) {
      defaultLyrics = controller.text;
      _refreshCanPush();
    }
    notifyListeners();
  }
}