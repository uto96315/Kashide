import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/top/top_page.dart';
import 'my_model.dart';



class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyModel>(
      create: (_) => MyModel()..getUserData(),
      child: Scaffold(
        body: Center(
          child: Consumer<MyModel>(builder: (context, model, child) {
            return Column(
              children: [
                const SizedBox(height: 100),
                Container(
                  alignment: Alignment.topLeft,
                  width: MediaQuery.of(context).size.width*0.9,
                  child: Column(
                    children: [

                      // ユーザーアイコン
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                  border: Border.all( color: Colors.grey ),
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.grey.shade200,
                                  image: (model.userImageURL != null)
                                    ? DecorationImage(image: NetworkImage(model.userImageURL!), fit: BoxFit.cover)
                                    : null
                              ),
                              child: (model.userImageURL == null)
                                  ? Icon(Icons.person)
                                  : null
                          ),
                          OutlinedButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                    EditUserDetailsPage(
                                      model.userName ?? "",
                                      model.userAge ?? "",
                                      model.userIntroduction ?? "",
                                      model.userGender ?? "",
                                      model.userFavorite!,
                                      model.userImageURL ?? ""  // todo: nullにするとエラーになるので他も修正必要
                                    )));
                              },
                              child: const Text("編集"))
                        ],
                      ),
                      const SizedBox( height: 20 ),


                      // ユーザーネーム
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(model.userName ?? "読み込み中...", style: const TextStyle( fontSize: 18 )),
                          const SizedBox( width: 10 ),
                        ],
                      ),
                      const SizedBox( height: 15 ),

                      // 自己紹介文
                      Text(
                          model.userIntroduction ?? "",
                          style: const TextStyle( fontSize: 16 )
                      ),

                      const SizedBox( height: 400 ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 40,
                        child: ElevatedButton(
                            onPressed: () async {
                              await model.logOut();
                              Navigator.popUntil(context, ModalRoute.withName("/"));
                            },
                            child: const Text("ログアウト", style: TextStyle( fontSize: 20 ))),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}