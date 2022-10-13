import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/top/top_page.dart';
import '../element/favorite/favorite_button.dart';
import 'my_model.dart';



class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MyModel>(
      create: (_) => MyModel()..getUserData()..getUserPosts(),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<MyModel>(builder: (context, model, child) {
              return Column(
                children: [
                  const SizedBox(height: 100),
                  Container(
                    alignment: Alignment.topLeft,
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      children: [

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
                              Padding(
                                padding: const EdgeInsets.only( right: 20 ),
                                child: OutlinedButton(
                                    onPressed: (){
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
                                    child: const Text("編集")),
                              )
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
                        Text(
                            model.userIntroduction ?? "",
                            style: const TextStyle( fontSize: 16 )
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
                                        MediaQuery.of(context).size.width * 0.8,
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
                                        width:
                                        MediaQuery.of(context).size.width*0.8,
                                        child: Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.end,
                                          children: [
                                            // 歌手名
                                            GestureDetector(
                                              onTap: (){
                                                Navigator.push(context, MaterialPageRoute(builder:(context) => GenrePage(post.artist, "artist")));
                                              },
                                              child: Row(
                                                children: [
                                                  const Text("歌手：", style: TextStyle( fontSize: 11)),
                                                  Text(post.artist, style: const TextStyle( fontSize: 11 )),
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
                                                  Text(post.singName, style: const TextStyle( fontSize: 11 )),
                                                ],
                                              ),
                                            ),
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
                          ))
                              .toList(),
                        ),
                        // 自分の投稿を表示----------------------



                        const SizedBox( height: 400 ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 40,
                          child: ElevatedButton(
                              onPressed: () async {
                                await model.logOut();
                                Navigator.popUntil(context, ModalRoute.withName("/"));
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: mainColor
                            ),
                              child: const Text("ログアウト", style: TextStyle( fontSize: 20 )),
                          ),
                        ),
                        const SizedBox( height: 200 ),
                      ],
                    ),
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