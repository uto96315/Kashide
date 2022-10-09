import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/registerUserDetails/register_user_details_page.dart';
import 'package:str_gram_beta/register/register_model.dart';
import 'package:url_launcher/url_launcher.dart';

import '../home/home_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegisterModel>(
      create: (_) => RegisterModel(),
      child: GestureDetector(
        onTap: (){FocusScope.of(context).unfocus();}, // キーボード以外をタップで閉じる
        child: Scaffold(
          appBar: AppBar(
            title: const Text("新規登録"),
            backgroundColor: mainColor,
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Consumer<RegisterModel>(builder: (context, model, child) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // メールアドレスの入力欄
                      TextField(
                        controller: model.registerEmailController,
                        autofocus: true,
                        decoration: const InputDecoration(labelText: 'メールアドレス'),
                        onChanged: (text) {
                          model.setEmail(text);
                        },
                      ),
                      const SizedBox(height: 30),

                      // パスワード入力欄
                      TextField(
                        controller: model.registerPasswordController,
                        obscureText: model.passObscure,
                        decoration: InputDecoration(
                            labelText: 'パスワード',
                            suffixIcon: IconButton(
                              icon: Icon((model.passObscure) ? Icons.visibility_off : Icons.visibility ),
                              onPressed: (){
                                model.changeObscure();
                              },
                            )
                        ),
                        onChanged: (text) {
                          model.setPassword(text);
                        },
                      ),
                      const SizedBox(height: 70),

                      // 利用規約同意ステップ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Checkbox(
                              value: model.consent,
                              onChanged: (value) {
                                model.setConsent(value!);
                              }),

                          // 利用規約同意ステップ
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "利用規約",
                                  style: const TextStyle(color: Colors.blue),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      launch(
                                          'https://uto96315.github.io/VtIL_privacy_policy/');
                                    },
                                ),
                                const TextSpan(
                                  text: "に同意する",
                                  style: TextStyle(color: Colors.black),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 50),

                      // 新規登録ボタン
                      SizedBox(
                        width: 200,
                        height: 50,
                        child: ElevatedButton(
                            onPressed: (model.consent == false)
                                ? null
                                : () async {
                                    model.startLoading();

                                    // 成功ならFirstAccessとしてEditUserPageに遷移させる
                                    try {
                                      await model.signIn();
                                      await Navigator.pushNamed(context, "/registerUserDetails");
                                    } catch (e) {
                                      final snackBar = SnackBar(
                                        backgroundColor: Colors.red,
                                        content: Text(e.toString()),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                    } finally {
                                      model.endLoading();
                                    }
                                  },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mainColor,
                          ),
                            child: const Text("登録する"),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ログインに遷移
                      TextButton(
                          onPressed: (){
                            Navigator.pushNamed(context, "/login");
                          },
                          child: const Text("またはログイン")
                      )
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
