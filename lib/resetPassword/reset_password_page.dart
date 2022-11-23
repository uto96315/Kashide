import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/resetPassword/reset_password_model.dart';



class ResetPasswordPage extends StatelessWidget {
  ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ResetPasswordModel>(
      create: (_) => ResetPasswordModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("パスワード再設定"),
          backgroundColor: mainColor,
        ),
        body: Center(
          child: Consumer<ResetPasswordModel>(builder: (context, model, child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width*0.8,
              child: Column(
                children: [
                  const SizedBox( height: 30 ),
                  const Text(
                      "登録されているEmailアドレス宛にパスワード再設定用のメールをお送りします",
                      style: TextStyle( fontSize: 16, height: 1.5 ),
                  ),
                  const SizedBox( height: 20 ),
                  const Text(
                      "注意：迷惑メールに入ることがあるので、届かない場合にはそちらをご確認ください",
                      style: TextStyle( fontSize: 13, height: 1.2, color: Colors.red ),
                  ),
                  const SizedBox( height: 40 ),
                  TextField(
                    controller: model.resetEmailController,
                    decoration: const InputDecoration(
                      labelText: "ご登録メールアドレス",
                      hintText: "example@test.com"
                    ),
                    onChanged: (text){
                      model.setEmail(text);
                    },
                  ),
                  const SizedBox( height: 50 ),

                  Text(model.alertMessage ?? ""),

                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                      ),
                      onPressed: ()async{
                        showCupertinoDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (_){
                              return CupertinoAlertDialog(
                                // title: const Text("パスワード再設定"),
                                content: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Text("パスワード再設定用メールを送信しますか？"),
                                ),
                                actions: [
                                  CupertinoDialogAction(
                                    child: const Text("はい"),
                                    onPressed: ()async{
                                      if(model.resetEmail == null) {
                                        model.setAlertMessage(model.resetEmail!);
                                        debugPrint("emailが記入されていないのでreturnします");
                                        return;
                                      }
                                      debugPrint("パスワードリセット用のメールを'${model.resetEmail}'宛に送信します");
                                      model.resetPassword(model.resetEmail!);
                                      Navigator.popUntil(context, (route) => route.isFirst);
                                    },
                                  ),
                                  CupertinoDialogAction(
                                    child: const Text("いいえ"),
                                    onPressed: (){
                                      debugPrint("パスワードリセット用のメールの送信が中止されました。");
                                      Navigator.pop(context); //Drawerを閉じる
                                    },
                                  ),
                                ],
                              );
                            }
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(15.0),
                        child: Text("送信する"),
                      )
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}