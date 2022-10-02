import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';



class EditUserDetailsModel extends ChangeNotifier {
  EditUserDetailsModel(this.userName, this.userIntroduction, this.userGender, this.userAge, this.userFavorite) {
    userNameController.text = userName ?? "名無しさん";
    userAgeController.text = userAge ?? "未設定";
    userIntroductionController.text = userIntroduction ?? "未設定";
    userGenderController.text = userGender ?? "未設定";
    userFavorite = userFavorite;
  }

  var user = FirebaseAuth.instance.currentUser;

  final userNameController = TextEditingController();
  final userIntroductionController = TextEditingController();
  final userAgeController = TextEditingController();
  final userGenderController = TextEditingController();


  String? userName;
  String? userIntroduction;
  String? userAge; // ユーザーの年代
  List<dynamic> userFavorite = []; // ユーザーの好みを入れる
  String? userGender; // ユーザーの性別
  List<String> genderList = ["男性", "女性", "ノンバイナリー"];

  List<String> favoriteList = [
    "邦楽",
    "洋楽",
    "ジャニーズ",
    "ロック",
    "KPOP",
    "R&B",
    "ラップ",
    "ヒップホップ",
    "レゲエ",
    "ジャズ",
    "アイドル",
    "エレクトロニカル",
    "クラシック",
    "演歌",
    "昭和歌謡",
    "その他",
  ];


  bool isLoading = false;

  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void endLoading() {
    isLoading = false;
    notifyListeners();
  }

  // ユーザーネームのセット
  void setUserName(String name) {
    userName = name;
    notifyListeners();
  }

  // 自己紹介のセット
  void setUserIntroduction(String introduction) {
    userIntroduction = introduction;
    notifyListeners();
  }

  // ユーザーの年代のセット
  void setUserAge(String age) {
    age ??= "不明";
    userAge = age;
    notifyListeners();
  }

  // 選択されたジャンルをリストに追加する処理
  void setFavorite(String favorite) {
    userFavorite.add(favorite);
    notifyListeners();
  }

  // 選択を外す処理
  void removeFavorite(String favorite) {
    userFavorite.remove(favorite);
    notifyListeners();
  }

  // ユーザーの性別のセット
  void setUserGender(String gender) {
    gender ??= "未選択";
    userGender = gender;
    notifyListeners();
  }

  // テスト用の処理
  void test() {
    print("${userName},${userAge},${userIntroduction},${userGender},${userFavorite}");
  }


  // ユーザー情報のアップデート用の関数
  Future updateUserData() async{
    var uid = user?.uid;
    userName = userNameController.text;
    userIntroduction = userIntroductionController.text;

    userName ??= "未設定";
    userAge ??= "未設定";
    userGender ??= "未設定";
    userIntroduction ??= "未設定";

    print(uid);

    final collection = FirebaseFirestore.instance
        .collection("users").doc(uid);
    if(user != null) {

      userName = userNameController.text;
      userIntroduction = userIntroductionController.text;
      userGender = userGenderController.text;
      userAge = userAgeController.text;

      await collection.set({
        "userName": userName,
        "age": userAge,
        "gender": userGender,
        "introduction": userIntroduction,
        "favorite": userFavorite,
        "createdAt": DateTime.now()
      });
    }
    print("ユーザーデータを保存しました。uid:${uid}");
  }


}