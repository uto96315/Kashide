import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'first_model.dart';



class FirstPage extends StatelessWidget {
  const FirstPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FirstModel>(
      create: (_) => FirstModel(),
      child: Scaffold(
        body: Center(
          child: Consumer<FirstModel>(builder: (context, model, child) {
            return Column(
              children: [
                const SizedBox(height: 100),
                Text("firstpage"),
                TextButton(
                    onPressed: (){
                      Navigator.popUntil(context,  ModalRoute.withName("/"));
                    },
                    child: const Text("Topへ")
                )
              ],
            );
          }),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: (){
            Navigator.pushNamed(context, "/post");
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
