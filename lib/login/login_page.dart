
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/home/home_page.dart';
import 'package:str_gram_beta/login/login_model.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginModel>(
        create: (_) => LoginModel(),
        child: Scaffold(
          appBar: AppBar(
            title: const Text("ログイン"),
          ),
          body: SingleChildScrollView(
            child: Center(
             child: Consumer<LoginModel>(builder: (context, model, child) {
              return SizedBox(
                width: MediaQuery.of(context).size.width*0.8,
                child: Column(
                  children: [
                    const SizedBox( height: 100 ),

                    // メールアドレスの入力欄
                    TextField(
                      controller: model.loginEmailController,
                      autofocus: true,
                      decoration: const InputDecoration(
                          labelText: 'メールアドレス'
                      ),
                      onChanged: (text) {
                        model.setEmail(text);
                      },
                    ),
                    const SizedBox( height: 30 ),

                    // パスワード入力欄
                    TextField(
                      controller: model.loginPasswordController,
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
                    const SizedBox( height: 200 ),

                    // ログインボタン
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: ElevatedButton(
                          onPressed: () async{
                            model.startLoading();

                            try {
                              await model.login();
                              await Navigator.pushNamed(context, "/home");
                            } catch(e) {
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
                          child: const Text("ログイン")
                      ),
                    ),
                    const SizedBox( height: 30 ),

                    // 新規登録に遷移
                    TextButton(
                        onPressed: (){
                          Navigator.pushNamed(context, "/register");
                        },
                        child: const Text("または新規登録")
                    )
                  ],
                ),
              );
            }),
        ),
          ),
      ),
    );
  }
}
