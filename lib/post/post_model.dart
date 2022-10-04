import 'package:flutter/cupertino.dart';


class PostModel extends ChangeNotifier {

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
}