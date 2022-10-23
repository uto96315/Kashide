import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/searchResult/searchResult_model.dart';

import '../element/favorite/favorite_button.dart';

class SearchResultPage extends StatelessWidget {
  SearchResultPage(this.searchWord, this.themeColor, {super.key});
  String searchWord;
  Color themeColor;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SearchResultModel>(
      create: (_) => SearchResultModel(searchWord)..searchFromText(searchWord),
      child: Scaffold(
        appBar: AppBar(
          title: Text("「$searchWord」", style: const TextStyle(fontSize: 15)),
          centerTitle: true,
          backgroundColor: themeColor,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<SearchResultModel>(builder: (context, model, child) {
              return Column(
                children: [
                  const SizedBox( height: 30 ),
                  Text(model.resultCount > 0
                      ? "全部で${model.resultCount}件の投稿が見つかりました。"
                      : "投稿が見つかりませんでした。"
                  ),
                  const SizedBox(height: 10),
                  const Divider( color: Colors.grey ),
                  Column(
                    // Listから生成-----------------------------------------------
                    children: model.resultList.map((result){
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: const BoxDecoration(
                            border: Border(
                                bottom: BorderSide(color: Colors.grey))),
                        child: Padding(
                          padding:
                          const EdgeInsets.only(top: 20, bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 10),

                              // ユーザー画像
                              Container(
                                  width: MediaQuery.of(context).size.width*0.1,
                                  height: MediaQuery.of(context).size.width*0.1,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.grey.shade200,
                                    image: (result.userImageUrl != "")
                                        ? DecorationImage(
                                        image: NetworkImage(
                                            result.userImageUrl),
                                        fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (result.userImageUrl != "")
                                      ? null
                                      : const Icon(Icons.person)
                              ),

                              Column(
                                children: [
                                  // ユーザーネーム
                                  SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width * 0.8,
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const SizedBox(width: 15),
                                            Text(result.userName),
                                          ],
                                        ),
                                        const SizedBox( width: 10 ),
                                        Text(result.createdAt, style: const TextStyle( color: Colors.grey )),

                                        // 報告及び削除ボタン
                                        // PopupMenuButton(
                                        //     icon: const Icon(Icons.more_horiz),
                                        //     onSelected: (value)async{
                                        //       if(value == "delete") {
                                        //         await model.deletePosts(post.id);
                                        //       } else if (value == "report") {
                                        //         await model.reportPosts(post.id);
                                        //       }
                                        //     },
                                        //     itemBuilder: (BuildContext context) =>  [
                                        //       (result.posterId == model.result)
                                        //           ? const PopupMenuItem(
                                        //         value: "delete",
                                        //         child: Text("削除する"),
                                        //       )
                                        //           : const PopupMenuItem(
                                        //         value: "report",
                                        //         child: Text("報告する"),
                                        //       )
                                        //     ]
                                        // )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),

                                  // 歌詞
                                  SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width *
                                        0.8,
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding:
                                        const EdgeInsets.only(left: 20),
                                        child: Text(result.text,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                                fontSize: 16, height: 1.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),


                                  // ジャンル一覧
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width*0.8,
                                    child: Wrap(
                                      runSpacing: 15,
                                      spacing: 10,
                                      children: result.genres.map((genre) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all( color: Colors.blue),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: Text(genre, style: const TextStyle( color: Colors.blue)),
                                            ),
                                          )
                                      ).toList(),
                                    ),
                                  ),
                                  const SizedBox( height: 15 ),

                                  // 曲名などのデータ
                                  // todo: 歌手名や曲名をタップでそのセグメントを見に行けるようにする
                                  SizedBox(
                                    width:
                                    MediaQuery.of(context).size.width *
                                        0.8,
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      children: [
                                        const Text("歌手：", style: TextStyle( fontSize: 11)),
                                        Text(result.artist, style: const TextStyle( fontSize: 11, color: Colors.black )),
                                        const SizedBox(width: 20),
                                        const Text("曲名：", style: TextStyle( fontSize: 11)),
                                        Text(result.singName, style: const TextStyle( fontSize: 11, color: Colors.black)),
                                        const SizedBox(width: 15),
                                      ],
                                    ),
                                  ),
                                  const SizedBox( height: 15 ),

                                  // いいねボタン
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width*0.5,
                                      height: 30,
                                      child: FavoriteButton(result.id, result.likedCount)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}