import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:url_launcher/url_launcher.dart';
import '../editPost/edit_post_page.dart';
import '../element/favorite/favorite_button.dart';
import '../postDetail/post_detail_page.dart';
import '../test/sideBar.dart';
import 'my_model.dart';



class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyModel>(
      create: (_) => MyModel()..getUserData()..getUserPosts(),
      child: Consumer<MyModel>(builder: (context, model, child) {
        return Scaffold(
          key: model.sidebarKey,
          body: SingleChildScrollView(
            child: Center(
              child: Consumer<MyModel>(builder: (context, model, child) {
                return Column(
                  children: [
                    const SizedBox(height: 50),
                    Container(
                      alignment: Alignment.topLeft,
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [

                          // メニューボタン
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox( width: 10 ),
                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: IconButton(
                                    onPressed: (){
                                      model.sidebarKey.currentState!.openEndDrawer();
                                    },
                                    icon: const Icon( Icons.menu, size: 40, color: Colors.black54 )
                                ),
                              ),
                            ],
                          ),

                          // ユーザーアイコン
                          Padding(
                            padding: const EdgeInsets.only( left: 20 ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                        border: Border.all( color: Colors.grey ),
                                        borderRadius: BorderRadius.circular(100),
                                        color: Colors.grey.shade200,
                                        image: (model.userImageURL != null || model.userImageURL != "")
                                            ? DecorationImage(image: NetworkImage(model.userImageURL ?? ""), fit: BoxFit.cover)
                                            : null
                                    ),
                                    child: (model.userImageURL == null || model.userImageURL == "")
                                        ? const Icon(Icons.person)
                                        : null
                                ),
                                const SizedBox( width: 10 ),
                              ],
                            ),
                          ),
                          const SizedBox( height: 15 ),


                          // ユーザーネーム
                          Padding(
                            padding: const EdgeInsets.only( left: 30 ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(model.userName ?? "読み込み中...", style: const TextStyle( fontSize: 20, fontWeight: FontWeight.bold )),
                                const SizedBox( width: 10 ),
                              ],
                            ),
                          ),
                          const SizedBox( height: 30 ),

                          // 自己紹介文
                          SizedBox(
                            width: MediaQuery.of(context).size.width*0.8,
                            child: Text(
                                model.userIntroduction ?? "",
                                style: const TextStyle( fontSize: 16 )
                            ),
                          ),
                          Container(
                            height: 50,
                            decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide( color: Colors.grey ))
                            ),
                          ),


                          // 自分の投稿を表示----------------------
                          Column(
                            children: model.userPostsList
                                .map((post) => Container(
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
                                          image: (model.userImageURL != "")
                                              ? DecorationImage(image: NetworkImage(model.userImageURL ?? ""), fit: BoxFit.cover)
                                              : null,
                                        ),
                                        child: (model.userImageURL != "")
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
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  const SizedBox(width: 15),
                                                  Text(model.userName ?? ""),
                                                ],
                                              ),
                                              const SizedBox(width: 10,),

                                              // 何分前
                                              Text(post.createdAt, style: const TextStyle( color: Colors.grey )),

                                              // 報告及び削除ボタン
                                              // 報告、編集及び削除ボタン
                                              PopupMenuButton(
                                                  icon: const Icon(Icons.more_horiz),
                                                  onSelected: (value)async{
                                                    if(value == "delete") {
                                                      await model.deletePosts(post.id);
                                                    } else if (value == "report") {
                                                      await model.reportPosts(post.id);
                                                    } else if(value == "edit") {
                                                      Navigator.push(context, MaterialPageRoute(builder: (context) => EditPostPage(post.id, post.text, post.artist, post.singName, post.genres, post.explanation, post.youtubeLink)));
                                                    }
                                                  },
                                                  itemBuilder: (BuildContext context) =>  [
                                                    const PopupMenuItem(value: "edit", child: Text("編集する")),
                                                    const PopupMenuItem(value: "delete", child: Text("削除する"))
                                                  ]
                                              )
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 10),

                                        // 説明
                                        GestureDetector(
                                          onTap: (){
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(post.id, false)));
                                          },
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                width: MediaQuery.of(context).size.width*0.8,
                                                child: Text(
                                                    post.explanation,
                                                    textAlign: TextAlign.left,
                                                    style: const TextStyle( fontSize: 15, height: 1.5)
                                                ),
                                              ),
                                              const SizedBox( height: 10 ),

                                              // 歌詞
                                              Container(
                                                width: MediaQuery.of(context).size.width*0.8,
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

                                        const SizedBox(height: 20),

                                        // ジャンル
                                        SizedBox(
                                          width: MediaQuery.of(context).size.width*0.8,
                                          child: Wrap(
                                            runSpacing: 15,
                                            spacing: 10,
                                            children: post.genres.map((genre) =>
                                                GestureDetector(
                                                  onTap: (){
                                                    Navigator.push(context, MaterialPageRoute(builder: (context) => GenrePage(genre, "genre")));
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
                                          width: MediaQuery.of(context).size.width*0.8,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Column(
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
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle( fontSize: 11 )
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox( width: 10 ),

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
                                                              overflow: TextOverflow.ellipsis,
                                                              style: const TextStyle( fontSize: 11 )
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
                                            width: MediaQuery.of(context).size.width*0.5,
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
                                                      onPressed: (){
                                                        launchUrl(Uri.parse(post.youtubeLink));
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
                                                const SizedBox( width: 35 ),


                                                GestureDetector(
                                                    onTap: (){
                                                      Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(post.id, true)));
                                                    },
                                                    child: Row(
                                                      children: [
                                                        const Icon(Icons.comment, color: Colors.grey ),
                                                        const SizedBox( width: 5 ),
                                                        Text(post.commentCount.toString() ?? "", style: const TextStyle( fontSize: 17 )),
                                                      ],
                                                    )
                                                ),
                                                const SizedBox( width: 20 ),
                                                SizedBox(
                                                    width: 50,
                                                    height: 30,
                                                    child: FavoriteButton(post.id, post.likedCount)
                                                ),
                                              ],
                                            )
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ))
                                .toList(),
                          ),
                          // 自分の投稿を表示----------------------




                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          endDrawer: Drawer(
            child: ListView(
              children: [
                const DrawerHeader(
                  child: Center(child: Text("メニュー", style: TextStyle(fontSize: 18))),
                ),

                // 編集
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('プロフィール編集', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) =>
                        EditUserDetailsPage(
                            model.userName ?? "",
                            model.userAge ?? "",
                            model.userIntroduction ?? "",
                            model.userGender ?? "",
                            model.userFavorite!,
                            model.userImageURL ?? ""  // todo: nullにするとエラーになるので他も修正必要
                        )));
                  },
                ),

                // ログアウト
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('ログアウト', style: TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () async{
                    showCupertinoDialog(
                        context: context,
                        builder: (_){
                          return CupertinoAlertDialog(
                            title: const Text("ログアウト"),
                            content: const Text("ログアウトしますか？"),
                            actions: [
                              CupertinoDialogAction(
                                child: const Text("はい"),
                                onPressed: ()async{
                                  debugPrint("ログアウトさせます");
                                  await model.logOut();
                                  Navigator.popUntil(context, ModalRoute.withName("/"));
                                },
                              ),
                              CupertinoDialogAction(
                                child: const Text("いいえ"),
                                onPressed: (){
                                  debugPrint("ログアウトがキャンセルされました");
                                  Navigator.pop(context); //Drawerを閉じる
                                },
                              ),
                            ],
                          );
                        }
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      ),
    );
  }
}