

import 'package:flutter/cupertino.dart';
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
      create: (_) => GenreModel(genre, condition)..getGenrePosts(genre)..getPlayListData(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(condition == "genre" ?"「$genre」の一覧" : genre, style: const TextStyle( fontSize: 16 ),),
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
                                    width: MediaQuery.of(context).size.width*0.7,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // youtubeリンク
                                        Container(
                                          child: post.youtubeLink != ""
                                              ? CupertinoButton(
                                              minSize: double.minPositive,
                                              padding: EdgeInsets.zero,
                                              onPressed: ()async{
                                                try {
                                                  await model.launchURL(post.youtubeLink);
                                                } catch(e) {
                                                  print(e.toString());
                                                }
                                              },
                                              child: Container(
                                                  decoration:  BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(100),
                                                  ),
                                                  child: const Icon(Icons.play_arrow, color: Colors.white) // todo: 後でYoutubeのロゴに変更
                                              )
                                          )
                                              : null,
                                        ),
                                        const SizedBox( width: 30 ),

                                        // いいねボタン
                                        SizedBox(
                                            width: 60,
                                            height: 30,
                                            child: FavoriteButton(post.id, post.likedCount)
                                        ),
                                        const SizedBox( width: 40 ),

                                        // プレイリストボタン
                                        GestureDetector(
                                            onTap: ()async{
                                              await showDialog(
                                                  context: context,
                                                  builder: (_){
                                                    return SimpleDialog(
                                                        title: const Text('この曲をプレイリストに追加する', style: TextStyle( fontSize: 15, fontWeight: FontWeight.bold, color: mainColor )),
                                                        children: [
                                                          for(final playlist in model.playList)
                                                            Padding(
                                                              padding: const EdgeInsets.only( top: 5, bottom: 0),
                                                              child: Container(
                                                                decoration: BoxDecoration(
                                                                    border: Border(
                                                                      top: BorderSide( color: Colors.grey.shade200 ),
                                                                    )
                                                                ),
                                                                child: SimpleDialogOption(
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.only( top: 5 ),
                                                                      child: Center(child: Text(playlist["playlistName"])),
                                                                    ),
                                                                    onPressed: ()async{
                                                                      await model.addToPlaylist(playlist["id"], post.artist, post.singName, post.youtubeLink, post.id);
                                                                      Navigator.pop(context);
                                                                      showDialog(
                                                                          context: context,
                                                                          builder: (_){
                                                                            return CupertinoAlertDialog(
                                                                              title: const Text("プレイリストに追加しました"),
                                                                              actions: [
                                                                                CupertinoDialogAction(
                                                                                  child: const Text("OK"),
                                                                                  onPressed: (){
                                                                                    Navigator.pop(context);
                                                                                  },
                                                                                )
                                                                              ],
                                                                            );
                                                                          }
                                                                      );
                                                                    }
                                                                ),
                                                              ),
                                                            ),
                                                          const SizedBox( height: 5 ),
                                                          Container(
                                                            decoration: BoxDecoration(
                                                              // color: Colors.grey.shade200,
                                                                border: Border(
                                                                  top: BorderSide( color: Colors.grey.shade200 ),
                                                                )
                                                            ),
                                                            child: Padding(
                                                              padding: const EdgeInsets.only( top: 10 ),
                                                              child: SimpleDialogOption(
                                                                child: Row(
                                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                                  children: const [
                                                                    Icon(Icons.add, color: Colors.blue),
                                                                    Text("プレイリストを新規作成", style: TextStyle( color: Colors.blue )),
                                                                  ],
                                                                ),
                                                                onPressed: ()async{
                                                                  await showDialog(context: context, builder: (_){
                                                                    return SimpleDialog(
                                                                      insetPadding: const EdgeInsets.all(10),
                                                                      title: const Text("プレイリストを追加する"),
                                                                      children: [
                                                                        SimpleDialogOption(
                                                                          child: SizedBox(
                                                                            width: MediaQuery.of(context).size.width*0.8,
                                                                            child: TextField(
                                                                              autofocus: true,
                                                                              controller: model.addPlaylistController,
                                                                              decoration: const InputDecoration(
                                                                                  hintText: "例）お気に入りの曲"
                                                                              ),
                                                                              onChanged: (text){
                                                                                model.setNewName(text);
                                                                              },
                                                                            ),
                                                                          ),
                                                                          // onPressed: () => Navigator.pop(context),
                                                                        ),
                                                                        SimpleDialogOption(
                                                                          child: ElevatedButton(
                                                                            // 新規追加
                                                                            onPressed: ()async{
                                                                              if(model.addPlaylistController.text.isEmpty){
                                                                                return;
                                                                              }
                                                                              try{
                                                                                await model.addNewPlaylist();
                                                                              } catch(e) {
                                                                                print(e.toString());
                                                                              }
                                                                              await model.getPlayListData();
                                                                              model.addPlaylistController.text = "";
                                                                              Navigator.pop(context);
                                                                            },
                                                                            style: ElevatedButton.styleFrom(
                                                                                backgroundColor: mainColor
                                                                            ),
                                                                            child: const Text("追加する"),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  });
                                                                  Navigator.pop(context);
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        ]
                                                    );
                                                  }
                                              );
                                            },
                                            child: const Icon(Icons.playlist_add, color: Colors.grey, size: 30,)
                                        ),
                                      ],
                                    ),
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