import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';



class RegisterUserDetailsModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

  final userNameController = TextEditingController();
  final userIntroductionController = TextEditingController();

  String? userName;
  String? userIntroduction;
  String? userAge; // ユーザーの年代
  var userFavorite = []; // ユーザーの好みを入れる
  String? userGender; // ユーザーの性別
  List<String> genderList = ["男性", "女性", "ノンバイナリー"];
  File? imageFile;
  String? storageURL;


  bool isLoading = false;

  // ローディング開始
  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  // ローディング終了
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

  // 新規登録用の処理
  Future registerUserData() async{
    var uid = user?.uid;
    var email = user?.email;
    userName = userNameController.text;
    userIntroduction = userIntroductionController.text;

    userName ??= "未設定";
    userAge ??= "未設定";
    userGender ??= "未設定";
    userIntroduction ??= "未設定";
    storageURL ??= "";

    // ファイルが選択されていればStorageに保存する
    if(imageFile != null) {
      await uploadImg();
    }

    print(storageURL ?? "URLが取得できませんでした");

    final collection = FirebaseFirestore.instance
        .collection("users").doc(uid);
    if(user != null) {
      await collection.set({
        "userName": userName,
        "email": email ?? "",
        "favorite": [""],
        "age": userAge,
        "gender": userGender,
        "introduction": userIntroduction,
        "createdAt": DateTime.now(),
        "iconUrl": storageURL
      });
    }
  }

  // image_picker
  Future pickImage() async{
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if(pickedFile != null) {
      imageFile = File(pickedFile.path);
    }
    notifyListeners();
  }


  // storageにアップする処理
  Future uploadImg() async{
    var uid = user?.uid;
    try {
      final storageRef = FirebaseStorage.instance.ref("users/$uid");
      final task = await storageRef.putFile(imageFile!);
      storageURL = await task.ref.getDownloadURL();
    } catch(e) {
      print(e);
      print(imageFile!);
    }
  }
}