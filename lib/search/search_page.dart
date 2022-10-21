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

                    // ジャンル一覧から生成
                    Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: model.wordObject.entries.map((word) {
                          return Column(
                            children: [
                              GestureDetector(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultPage(word.key, word.value[1])));
                                  model.searchTextController.clear(); //
                                },
                                child: Container(
                                width: MediaQuery.of(context).size.width * 0.8,
                                decoration: BoxDecoration(
                                    border: Border.all(color: word.value[1]),
                                    borderRadius: BorderRadius.circular(15),
                                    color: Colors.white,
                                    boxShadow: [
                                       BoxShadow(
                                          color: Colors.grey.shade200,
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: const Offset(2, 2),
                                      )
                                    ]
                                ),
                                alignment: Alignment.center,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 30, bottom: 30),

                                  // ここがジャンルのテキスト
                                  child: Text(
                                      word.key,
                                      style: TextStyle(
                                          color: word.value[1],
                                          fontSize: 17
                                      )
                                  ),
                                )),
                              ),
                              const SizedBox( height: 20 ),
                            ],
                          );
                    }).toList())
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
