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
                      SizedBox(
                          width: 100,
                          height: 100,
                          child: (model.userImageURL != null)
                          ? Image.network(model.userImageURL!)
                          : null
                      ),


                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(model.userName ?? "読み込み中...", style: const TextStyle( fontSize: 18 )),
                          const SizedBox( width: 10 ),
                          OutlinedButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) =>
                                    EditUserDetailsPage(
                                        model.userName ?? "",
                                        model.userAge ?? "",
                                        model.userIntroduction ?? "",
                                        model.userGender ?? "",
                                        model.userFavorite!,
                                    )));
                              },
                              child: const Text("編集"))
                        ],
                      ),
                      const SizedBox( height: 10 ),
                      Text(model.userIntroduction ?? "", style: const TextStyle( fontSize: 16 )),

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