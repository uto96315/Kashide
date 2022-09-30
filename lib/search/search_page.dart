import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/search/search_model.dart';



class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchModel>(
      create: (_) => SearchModel(),
      child: Scaffold(
        body: Center(
          child: Consumer<SearchModel>(builder: (context, model, child) {
            return Column(
              children: [
                const SizedBox(height: 100),
                Text("search_page"),
              ],
            );
          }),
        ),
      ),
    );
  }
}