import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';



class MyModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;
  String? userName;
  String? userIntroduction;
  String? userAge;
  String? userGender;
  List<dynamic>? userFavorite;

  // ユーザー情報の取得
  // todo: なぜか取得がうまくいっていない...
  Future getUserData() async{
    var uid = user?.uid;
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final get = await doc.get();
    final data = get.data();

    userName = data?["userName"];
    userIntroduction = data?["introduction"];
    userAge = data?["age"];
    userGender = data?["gender"];
    userFavorite = data?["favorite"];

    notifyListeners();
  }


  //　ログアウトさせる処理
  Future logOut() async{
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

}
