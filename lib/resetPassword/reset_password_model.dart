

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class ResetPasswordModel extends ChangeNotifier{

  final resetEmailController = TextEditingController();
  String? resetEmail;
  String? alertMessage;


  // 再設定用のemail
  setEmail(String text) {
    resetEmail = text;
    notifyListeners();
  }


  // パスワード再設定用
  Future resetPassword(String email) async{
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    notifyListeners();
  }

  // アラートメッセージ設定
  void setAlertMessage(String email){
    if(email.isEmpty){
      alertMessage = "メールアドレスが入力されていません。";
    } else if(email.length <= 3) {
      alertMessage = "正しいメールアドレスを入力してください。";
    }
    notifyListeners();
  }


}

