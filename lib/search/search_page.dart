import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/search/search_model.dart';
import 'package:str_gram_beta/searchResult/searchResult_page.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: ChangeNotifierProvider<SearchModel>(
        create: (_) => SearchModel()..getUserData(),
        child: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: Consumer<SearchModel>(builder: (context, model, child) {
                return Column(
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: TextField(
                        controller: model.searchTextController,
                        decoration: InputDecoration(
                          labelText: "どんな歌詞と出会いたい？",
                          suffixIcon: IconButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultPage(model.searchText!, mainColor)));
                                model.searchTextController.clear(); // 空にする
                              },
                              icon: const Icon(Icons.search))
                        ),
                        onSubmitted: (text){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultPage(text, mainColor)));
                          model.searchTextController.clear(); // 空にする
                        },
                        onChanged: (text){
                          model.setText(text);
                        },
                      ),
                    ),

                    const SizedBox(height: 30),

                    // TODO: ジャンルの一覧を表示する

                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
