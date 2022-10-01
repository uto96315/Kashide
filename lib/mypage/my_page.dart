import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(model.userName ?? "読み込み中...", style: const TextStyle( fontSize: 18 )),
                          const SizedBox( width: 10 ),
                          OutlinedButton(
                              onPressed: (){
                                Navigator.pushNamed(context, "/editUserDetails");
                              },
                              child: const Text("編集"))
                        ],
                      ),
                      const SizedBox( height: 10 ),
                      Text(model.userIntroduction ?? "", style: const TextStyle( fontSize: 16 )),
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