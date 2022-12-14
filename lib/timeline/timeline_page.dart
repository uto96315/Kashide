import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/howToUse/how_to_use_page.dart';
import 'package:str_gram_beta/post/post_page.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import '../common/ThemeColor.dart';
import '../element/favorite/favorite_button.dart';
import 'timeline_model.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimelineModel>(
      create: (_) => TimelineModel()..getPosts()..getPlayListData(),
      child: Consumer<TimelineModel>(builder: (context, model, child){
        return Scaffold(
          appBar: AppBar(
            title: const Text("Kashide"),
            automaticallyImplyLeading: false,
            backgroundColor: mainColor,
            actions: [
              IconButton(
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>const HowToUsePage()));
                  },
                  icon: const Icon(Icons.help_outline)
              ),
            ],
          ),

          body: RefreshIndicator(  // 下にスワイプでリフレッシュ
            color: mainColor,
            onRefresh: ()async{
              await model.getPosts();
              debugPrint("更新しました");
            },
            child: SingleChildScrollView(
              child: Center(
                child: Consumer<TimelineModel>(builder: (context, model, child) {
                  return Column(children: [
                    const SizedBox(height: 10),
                    Column(
                      children: model.postsList
                          .map((post)  {
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

                                          // 報告、編集及び削除ボタン
                                          PopupMenuButton(
                                              icon: const Icon(Icons.more_horiz),
                                              onSelected: (value)async{
                                                if(value == "delete") {
                                                  // 削除のアラート表示
                                                  showCupertinoDialog(
                                                      context: context,
                                                      builder: (_){
                                                        return CupertinoAlertDialog(
                                                          content: const Text("削除しますか？"),
                                                          actions: [
                                                            CupertinoDialogAction(
                                                              child: const Text('はい'),
                                                              onPressed: () async{
                                                                await model.deletePosts(post.id);
                                                                Navigator.pop(context);
                                                              },
                                                            ),
                                                            CupertinoDialogAction(
                                                              child: const Text('いいえ'),
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      }
                                                  );
                                                } else if (value == "report") {
                                                  showCupertinoDialog(
                                                      context: context,
                                                      builder: (_){
                                                        return CupertinoAlertDialog(
                                                          content: const Text("報告しますか？"),
                                                          actions: [
                                                            CupertinoDialogAction(
                                                              child: const Text('はい'),
                                                              onPressed: () async{
                                                                await model.reportPosts(post.id);
                                                                Navigator.pop(context);
                                                              },
                                                            ),
                                                            CupertinoDialogAction(
                                                              child: const Text('いいえ'),
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                              },
                                                            ),
                                                          ],
                                                        );
                                                      }
                                                  );
                                                } else if(value == "edit") {
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => EditPostPage(post.id, post.text, post.artist, post.singName, post.genres, post.explanation, post.youtubeLink)));
                                                }
                                              },
                                              itemBuilder: (BuildContext context) =>  [
                                                (post.posterId == model.uid)
                                                    ? const PopupMenuItem(value: "edit", child: Text("編集する"))
                                                    : const PopupMenuItem(value: "report", child: Text("報告する")),
                                                (post.posterId == model.uid)
                                                    ? const PopupMenuItem(value: "delete", child: Text("削除する"))
                                                    : const PopupMenuItem(value: "", child: Text("")), // todo: 何も表示しないようにしたい(null的な)
                                              ]
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // 歌詞と理由
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(post.id, false)));
                                      },
                                      child: SizedBox(
                                        width:
                                        MediaQuery.of(context).size.width *
                                            0.8,
                                        child: Container(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding:
                                            const EdgeInsets.only(left: 20),
                                            child: Column(
                                              children: [
                                                // 説明
                                                SizedBox(
                                                  width: MediaQuery.of(context).size.width,
                                                  child: Text(
                                                      post.explanation,
                                                      textAlign: TextAlign.left,
                                                      style: const TextStyle( fontSize: 15, height: 1.5)
                                                  ),
                                                ),

                                                const SizedBox( height: 10 ),

                                                // 歌詞
                                                Container(
                                                  width: MediaQuery.of(context).size.width,
                                                  decoration: BoxDecoration(
                                                      color: Colors.grey.shade200
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text('---\n${post.text}\n---',
                                                        textAlign: TextAlign.left,
                                                        style: const TextStyle(fontSize: 16, height: 1.5)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),


                                    // ジャンル一覧
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width*0.8,
                                      child: Wrap(
                                        alignment: WrapAlignment.center,
                                        runSpacing: 15,
                                        spacing: 10,
                                        children: post.genres.map((genre) =>
                                            GestureDetector(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder:(context) => GenrePage(genre, "genre")));
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all( color: Colors.blue ),
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Text(genre, style: const TextStyle( color: Colors.blue ),),
                                                ),
                                              ),
                                            )
                                        ).toList(),
                                      ),
                                    ),
                                    const SizedBox( height: 15 ),

                                    // 曲名などのデータ
                                    // todo: 歌手名や曲名をタップでそのセグメントを見に行けるようにする
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              // 歌手名
                                              GestureDetector(
                                                onTap: (){
                                                  Navigator.push(context, MaterialPageRoute(builder:(context) => GenrePage(post.artist, "artist")));
                                                },
                                                child: Row(
                                                  children: [
                                                    const Text("歌手：", style: TextStyle( fontSize: 11)),
                                                    SizedBox(
                                                      width: 100,
                                                      child: Text(
                                                          post.artist,
                                                          style: const TextStyle( fontSize: 11 ),
                                                          overflow: TextOverflow.ellipsis
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              const SizedBox(height: 5),

                                              // 曲名
                                              GestureDetector(
                                                onTap: (){
                                                  Navigator.push(context, MaterialPageRoute(builder:(context) => GenrePage(post.singName, "singName")));
                                                },
                                                child: Row(
                                                  children: [
                                                    const Text("曲名：", style: TextStyle( fontSize: 11)),
                                                    SizedBox(
                                                      width: 100,
                                                      child: Text(
                                                        post.singName,
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle( fontSize: 11 ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox( height: 15 ),

                                    // いいね、コメントボタン
                                    SizedBox(
                                        width: MediaQuery.of(context).size.width*0.7,
                                        height: 30,
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
                                            const SizedBox( width: 40 ),

                                            // コメントボタン
                                            GestureDetector(
                                                onTap: (){
                                                  Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(post.id, true)));
                                                },
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.comment, color: Colors.grey ),
                                                    const SizedBox( width: 5 ),
                                                    Text(post.commentCount.toString(), style: const TextStyle( fontSize: 17 )),
                                                  ],
                                                )
                                            ),
                                            const SizedBox( width: 10 ),

                                            // いいねボタン
                                            SizedBox(
                                                width: 60,
                                                height: 30,
                                                child: FavoriteButton(post.id, post.likedCount)
                                            ),
                                            const SizedBox( width: 30 ),

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
                                        )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      )
                          .toList(),
                    ),
                  ]);
                }),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context)=>PostPage(null)));
            },
            backgroundColor: mainColor,
            child: const Icon(Icons.add),
          ),
        );
      })
    );
  }
}
