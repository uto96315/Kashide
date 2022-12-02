import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';


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
  bool genreAddFlag = false;  // その他が選択された場合にテキストフィールドを出すかのフラグ

  final clipBoardText = Clipboard.getData(Clipboard.kTextPlain);  // ペーストする時用

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
    "その他",
  ];


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
    }
  }

  // ジャンルを付与する処理
  void setGenre(String genre) {
    if(genres.contains(genre)) {
      // genres.remove(genre);
      return;
    } else {
      if(genres.length == 3) {
        genreMaxLength = false;
        return;
      }
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
    if(genreMaxLength == false) {
      genreMaxLength = true;
    }

    notifyListeners();
  }

  // 投稿する処理
  Future post() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("posts");

    explanation = explanationController.text;
    lyrics = lyricsController.text;
    singerName = singerNameController.text;
    singName = singNameController.text;
    youtubeLink = youtubeLinkController.text;

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

  // その他が選択された際にジャンルを追加する
  void addGenre(String genre){
    if(genres.contains(genre)){
      return;
    }
    defaultGenresList.add(genre);
    if(genres.length == 3) {
      return;
    }
    genres.add(genre);
    notifyListeners();
  }

  // ペーストする関数
   void pasteText(controller) async{
     var data = await Clipboard.getData(Clipboard.kTextPlain);
     controller.text = data?.text.toString() ?? "";
     if(data != null) {
       canPush = true;
     }
     print(lyricsController.text);
     notifyListeners();
   }
}