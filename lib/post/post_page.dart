import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/post/post_model.dart';

class PostPage extends StatelessWidget {
  PostPage(this.defaultGenre, {super.key});

  String? defaultGenre; // ジャンルから遷移した場合以外はnullでOK

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostModel>(
      create: (_) => PostModel(defaultGenre)..setDefaultGenre(defaultGenre)..getDefaultGenres(),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text("投稿"),
            backgroundColor: mainColor,
            actions: [
              Consumer<PostModel>(builder: (context, model, child) {
                return // 投稿ボタン
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MaterialButton(
                          color: (model.canPush) ? Colors.white : Colors.white60,
                          onPressed: (model.canPush)
                           ? () async {
                            await model.post();  // 投稿実行
                            showCupertinoDialog(
                                  context: context,
                                  builder: (_){
                                    return CupertinoAlertDialog(
                                      content: const Text("投稿しました"),
                                      actions: [
                                        CupertinoDialogAction(
                                            child: const Text("OK"),
                                            onPressed: (){
                                              Navigator.pushNamed(context, "/home");
                                            },
                                        )
                                      ],
                                    );
                                  }
                              );
                             }
                            : (){
                            showCupertinoDialog(
                                context: context,
                                builder: (_){
                                  return CupertinoAlertDialog(
                                    title: const Text("投稿エラー", style: TextStyle( fontWeight: FontWeight.normal )),
                                    content: const Padding(
                                      padding: EdgeInsets.all(10.0),
                                      child: Text("歌詞を入力してください"),
                                    ),
                                    actions: [
                                      CupertinoDialogAction(
                                        child: const Text("OK"),
                                        onPressed: ()async{
                                          debugPrint("承認されました");
                                          Navigator.pop(context); //Drawerを閉じる
                                        },
                                      ),
                                    ],
                                  );
                                }
                            );
                          },
                      child: const Padding(
                      padding: EdgeInsets.only(right: 15, left: 15),
                      child: Text(
                        "投稿する",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: mainColor
                        ),
                      ),
                    ),
                  ),
                );
              })
            ],
          ),
          body: SingleChildScrollView(
            child: Center(
              child: Consumer<PostModel>(builder: (context, model, child) {
                return SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    children: [
                      const SizedBox(height: 50),

                      // 好きな理由記入欄
                      TextField(
                        controller: model.explanationController,
                        maxLines: null,
                        maxLength: 300,
                        decoration: const InputDecoration(
                          labelText: "この曲への思い（任意）",
                        ),
                        onChanged: (text) {
                          model.setExplanation(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // お気に入りの歌詞入力欄
                      TextField(
                        controller: model.lyricsController,
                        maxLines: null,
                        maxLength: 300,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: "心に響いた歌詞を入力してみよう(必須)",
                          labelStyle: const TextStyle( color: Colors.red, fontSize: 14 ),
                          suffixIcon: IconButton(
                              onPressed: (){
                                model.pasteText(model.lyricsController);
                              },
                              icon: const Icon(Icons.paste)
                          )
                        ),
                        onChanged: (text) {
                          model.setLyrics(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // 歌手名入力欄
                      TextField(
                        controller: model.singerNameController,
                        maxLength: 50,
                        decoration: InputDecoration(
                          labelText: "歌手名(任意)",
                            suffixIcon: IconButton(
                                onPressed: (){
                                  model.pasteText(model.singerNameController);
                                },
                                icon: const Icon(Icons.paste)
                            )
                        ),
                        onChanged: (text) {
                          model.setSinger(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // 曲名入力欄
                      TextField(
                        controller: model.singNameController,
                        maxLength: 50,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: "曲名(任意)",
                            suffixIcon: IconButton(
                                onPressed: (){
                                  model.pasteText(model.singNameController);
                                },
                                icon: const Icon(Icons.paste)
                            )
                        ),
                        onChanged: (text) {
                          model.setSing(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // Youtubeなどのリンクを貼る
                      TextField(
                        controller: model.youtubeLinkController,
                        maxLines: 1,
                        maxLength: 200,
                        decoration: InputDecoration(
                            labelText: "Youtubeリンク",
                            suffixIcon: IconButton(
                                onPressed: (){
                                  model.pasteText(model.youtubeLinkController);
                                },
                                icon: const Icon(Icons.paste)
                            )
                        ),
                        onChanged: (text){
                          model.setYoutubeLink(text);
                        },
                      ),
                      const SizedBox(height: 15),


                      // デフォルトジャンルリスト
                      Row(
                        children: const [
                          Text("ジャンル(タップで選択)", style: TextStyle( fontSize: 17, color: Colors.black54 ),),
                          SizedBox( width: 10 ),
                        ],
                      ),
                      Row(
                        children: const [
                          Text("※最大三つまで", style: TextStyle( fontSize: 12, color: Colors.black54 )),
                          SizedBox( width: 10 ),
                        ],
                      ),
                      const SizedBox( height: 20 ),
                      Wrap(
                        runSpacing: 15,
                        spacing: 10,
                        children: [
                          for(final genre in model.defaultGenresList)
                            InkWell(
                              onTap: (){
                                if(model.genres.contains(genre)) {
                                  model.deleteGenre(genre);
                                  return;
                                }
                                model.setGenre(genre);
                              },
                              child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 8),
                                  decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(Radius.circular(32)),
                                      border: Border.all(width: 2, color:
                                      (model.genres.contains(genre)) ? mainColor : Colors.blue),
                                      color: Colors.white),
                                  child: RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                          text: genre,
                                          style: TextStyle(
                                              color: model.genres.contains(genre) ? mainColor : Colors.blue)
                                      ),
                                    ]),
                                  )),
                            ),
                        ],
                      ),

                      const SizedBox( height: 30 ),


                      TextFormField(
                        controller: model.genreController,
                        autofocus: false,
                        onFieldSubmitted: (text){
                          model.addGenre(text);
                          model.genreController.clear();
                        },
                        decoration: const InputDecoration(
                          labelText: "ジャンルを追加する",
                          hintText: "完了またはエンターを押すと追加できます",
                        ),
                      ),

                      const SizedBox(height: 200),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
