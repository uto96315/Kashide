

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/post/post_page.dart';
import '../element/favorite/favorite_button.dart';
import 'genre_model.dart';

class GenrePage extends StatelessWidget {
  GenrePage(this.genre,this.condition, {super.key});
  String genre;
  String condition;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GenreModel>(
      create: (_) => GenreModel(genre, condition)..getGenrePosts(genre),
      child: Scaffold(
        appBar: AppBar(
          title: Text(condition == "genre" ?"「$genre」の一覧" : "$genre"),
          centerTitle: true,
          backgroundColor: mainColor,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<GenreModel>(builder: (context, model, child) {
              return Column(
                children: [
                  const SizedBox( height: 20 ),

                  Text( model.postCount != 0
                      ? "全部で${model.postCount.toString()}件の投稿が見つかりました。"
                      : "このジャンルの投稿はまだありません。"
                  ),

                  const SizedBox( height: 20 ),

                  Column(
                    // ここからmap処理---------------------------
                    children: model.genrePostsList.map((post){
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
                                    image: (post.userImageUrl != "")
                                        ? DecorationImage(
                                        image: NetworkImage(
                                            post.userImageUrl),
                                        fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (post.userImageUrl != "")
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
                                            Text(post.userName),
                                          ],
                                        ),
                                        const SizedBox( width: 10 ),
                                        Text(post.createdAt, style: const TextStyle( color: Colors.grey )),

                                        // 報告及び削除ボタン
                                        PopupMenuButton(
                                            icon: const Icon(Icons.more_horiz),
                                            onSelected: (value)async{
                                              if(value == "delete") {
                                                await model.deletePosts(post.id);
                                              } else if (value == "report") {
                                                await model.reportPosts(post.id);
                                              }
                                            },
                                            itemBuilder: (BuildContext context) =>  [
                                              (post.posterId == model.uid)
                                                  ? const PopupMenuItem(
                                                value: "delete",
                                                child: Text("削除する"),
                                              )
                                                  : const PopupMenuItem(
                                                value: "report",
                                                child: Text("報告する"),
                                              )
                                            ]
                                        )
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
                                        child: Text(post.text,
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
                                      children: post.genres.map((genre) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all( color: this.genre != genre ? Colors.blue : Colors.red ),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: Text(genre, style: TextStyle( color: this.genre != genre ? Colors.blue : Colors.red ),),
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
                                        Text(post.artist, style: TextStyle( fontSize: 11, color: condition == "artist" ? Colors.red : Colors.black )),
                                        const SizedBox(width: 20),
                                        const Text("曲名：", style: TextStyle( fontSize: 11)),
                                        Text(post.singName, style: TextStyle( fontSize: 11, color: condition == "singName" ? Colors.red : Colors.black)),
                                        const SizedBox(width: 15),
                                      ],
                                    ),
                                  ),
                                  const SizedBox( height: 15 ),

                                  // いいねボタン
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width*0.5,
                                      height: 30,
                                      child: FavoriteButton(post.id, post.likedCount)
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 50)
                ],
              );
            }),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(context,MaterialPageRoute(builder: (context)=>PostPage(genre)));
          },
          backgroundColor: mainColor,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}