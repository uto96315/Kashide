import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/searchResult/searchResult_model.dart';

class SearchResultPage extends StatelessWidget {
  SearchResultPage(this.searchWord, this.themeColor, {super.key});
  String searchWord;
  Color themeColor;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchResultModel>(
      create: (_) => SearchResultModel(searchWord),
      child: Scaffold(
        appBar: AppBar(
          title: Text("「$searchWord」", style: const TextStyle(fontSize: 15)),
          centerTitle: true,
          backgroundColor: themeColor,
        ),
        body: Center(
          child: Consumer<SearchResultModel>(builder: (context, model, child) {
            return Column();
          }),
        ),
      ),
    );
  }
}