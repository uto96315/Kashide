import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class RegisterModel extends ChangeNotifier {
  final registerEmailController = TextEditingController();
  final registerPasswordController = TextEditingController();

  String? email;
  String? password;

  bool isLoading = false;
  bool passObscure = true;
  bool consent = false; // 利用規約に同意しているか

  // ローディング開始
  void startLoading() {
    isLoading = true;
    notifyListeners();
  }

  // ローデイング終了
  void endLoading() {
    isLoading = false;
    notifyListeners();
  }

  // メールアドレスのセット
  void setEmail(String email) {
    this.email = email;
    notifyListeners();
  }

  // パスワードのセット
  void setPassword(String password) {
    this.password = password;
    notifyListeners();
  }

  // パスワードの可視・不可視の切り替え
  void changeObscure() {
    passObscure = !passObscure;
    notifyListeners();
  }

  // 同意にチェックが入ったかどうか
  void setConsent(bool value) {
    consent = value;
    notifyListeners();
  }

  // ログインに関する関数
  Future signIn() async {
    email = registerEmailController.text;
    password = registerPasswordController.text;

    if (email != null && password != null) {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email!, password: password!);
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser!.uid;
    } else {
      // パスワードまたはメールアドレスがブランクだった場合の処理
    }
  }

  Future registerBlankData()async{
    var uid = FirebaseAuth.instance.currentUser?.uid;
    final collection = FirebaseFirestore.instance
        .collection("users").doc(uid);

    if(uid != null) {
      await collection.update({
        "userName": "",
        "email": email ?? "",
        "favorite": [""],
        "age": "99以上",
        "gender": "ノンバイナリー", // 未指定の場合にはノンバイナリーにする
        "introduction": "",
        "createdAt": DateTime.now(),
        "iconUrl": "",
      });
    }
  }
}
