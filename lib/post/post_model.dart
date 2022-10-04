import 'package:flutter/cupertino.dart';


class PostModel extends ChangeNotifier {

  final lyricsController = TextEditingController();
  final singerNameController = TextEditingController();

  String? lyrics;
  String? singerName;

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
}