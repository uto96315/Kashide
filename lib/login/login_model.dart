

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class LoginModel extends ChangeNotifier {
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  String? email;
  String? password;

  bool isLoading = false;
  bool passObscure = true; // パスワードの可視・不可視の切り替え

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

  // ログインに関する関数
  Future login() async{
    email = loginEmailController.text;
    password = loginPasswordController.text;

    if(email != null && password != null) {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password!);
      final currentUser = FirebaseAuth.instance.currentUser;
      final uid = currentUser!.uid;
    } else {
      // パスワードまたはメールアドレスがブランクだった場合の処理
    }
  }
}