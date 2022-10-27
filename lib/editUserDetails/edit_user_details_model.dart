import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';



class EditUserDetailsModel extends ChangeNotifier {
  EditUserDetailsModel(this.userName, this.userIntroduction, this.userGender, this.userAge, this.userFavorite, this.userImageUrl) {
    userNameController.text = userName ?? "名無しさん";
    userAgeController.text = userAge ?? "未設定";
    userIntroductionController.text = userIntroduction ?? "未設定";
    userGenderController.text = userGender ?? "未設定";
    userFavorite = userFavorite;
    userImageUrl = userImageUrl;
  }

  var user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();

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
  String? userImageUrl; // 引数で受け取ってくるURL

  bool isSetted = false; // 画像が変更されたかどうかのフラグ
  bool canPush = false; // 登録ボタンを押せるかどうかのフラグ
  File? imageFile; // セットされたファイル本体
  String? storageURL; // 新たにStorageにセットしたURL

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
    checkCanPush();
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

  // ボタンを押せるかどうかの検出
  void checkCanPush() {
    canPush = userName!.isNotEmpty;
    notifyListeners();
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


    // 変更されていた場合には変更後を採用する
    if(isSetted == true) {
      await uploadImg();
      notifyListeners();
    }

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
        "createdAt": DateTime.now(),
        "iconUrl": userImageUrl
      });
    }
  }


  // ユーザーの削除処理
  // todo: 修正必要（消せていない）
  Future deleteUser() async{
    var uid = user?.uid;

    await setDeletedUser(uid!); // 記録

    // FireStoreから削除
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    await doc.delete();

    // Authから削除
    await user?.delete();
    await FirebaseAuth.instance.signOut();

    // 紐づく投稿を削除する
    await deletePosts();

    // Storageの画像を削除する
    await deleteFromStorage();
  }



  // 削除するユーザーの投稿を削除する
  Future deletePosts() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("posts").where("posterId", isEqualTo: uid);
    final data = await doc.get();
    // 削除はForEachで回す
    data.docs.forEach((doc) async{
      await doc.reference.delete();
      print(doc.id);
    });
  }



  // 削除したユーザーを記録する処理
  Future setDeletedUser(String uid) async{
    final doc = FirebaseFirestore.instance.collection("deletedUsers").doc(uid);
    await doc.set({
      "uid": uid,
      "email": user?.email,
      "deletedAt": DateTime.now(),
    });
  }


  //　以下ストレージ関係の処理------

  // 画像が変更されたかどうかのフラグ
  void setIsSetted() {
    if(isSetted == false) {
      isSetted = true;
    }
    print("isSetted: ${isSetted}");
    notifyListeners();
  }


  // image_picker
  Future pickImage() async{
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if(pickedFile != null) {
      imageFile = File(pickedFile.path);
    }
    setIsSetted(); // ここで変更されたかどうかのフラグを変更
    notifyListeners();
  }


  // storageにアップする処理
  Future uploadImg() async{
    var uid = user?.uid;
    try {
      final storageRef = FirebaseStorage.instance.ref("userIcons").child("$uid").child("userIcon");
      final task = await storageRef.putFile(imageFile!);
      storageURL = await task.ref.getDownloadURL();
      userImageUrl = storageURL; // ここで書き換え
      print("画像を変更しました");
    } catch(e) {
      print(e);
    }
  }


  // アカウント削除時にstorageからユーザーのデータを削除する
  Future deleteFromStorage() async{
    var uid = FirebaseAuth.instance.currentUser?.uid;
    try{
      final storageRef = FirebaseStorage.instance
          .ref("userIcons").child("$uid").child("userIcon");

      await storageRef.delete();
    } catch (e) {
      debugPrint("アカウントの画像を削除しました");
    }
  }
}