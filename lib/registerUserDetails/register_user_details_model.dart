import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';



class EditUserDetailsModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;

  final userNameController = TextEditingController();
  final userIntroductionController = TextEditingController();

  String? userName;
  String? userIntroduction;
  String? userAge; // ユーザーの年代
  var userFavorite = []; // ユーザーの好みを入れる
  String? userGender; // ユーザーの性別
  List<String> genderList = ["男性", "女性", "ノンバイナリー"];


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

  // ユーザーの好みのセット
  void setUserFavorite([favorite]) {
    favorite ??= "未選択";
    userFavorite = favorite;
    notifyListeners();
  }

  // ユーザーの性別のセット
  void setUserGender(String gender) {
    gender ??= "未選択";
    userGender = gender;
    notifyListeners();
  }

  void test() {
    print("${userName},${userAge},${userIntroduction},${userGender},${userFavorite}");
  }

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
      await collection.set({
        "userName": userName,
        "age": userAge,
        "gender": userGender,
        "introduction": userIntroduction,
        "createdAt": DateTime.now()
      });
    }
    print("ユーザーデータを保存しました。uid:${uid}");
  }
}