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
      create: (_) => PostModel(defaultGenre)..setDefaultGenre(defaultGenre),
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: mainColor,
            // toolbarHeight: MediaQuery.of(context).size.height * 0.07,
            actions: [
              Consumer<PostModel>(builder: (context, model, child) {
                return // 投稿ボタン
                    Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: MaterialButton(
                          color: (model.canPush) ? Colors.white : null,
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
                            : null,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 15, left: 15),
                      child: Text(
                        "投稿する",
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: mainColor),
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
                        autofocus: true,
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
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "心に響いた歌詞を入力しましょう(必須)",
                          labelStyle: TextStyle( color: Colors.red )
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
                        decoration: const InputDecoration(
                          labelText: "歌手名(任意)",
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
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: "曲名(任意)",
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
                        decoration: const InputDecoration(
                            labelText: "Youtubeリンク",
                            // prefixIcon: Icon(Icons.add)
                        ),
                        onChanged: (text){
                          model.setYoutubeLink(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // ジャンル追加欄
                      TextFormField(
                        controller: model.genreController,
                        enabled: model.genreMaxLength,
                        maxLength: 15,
                        decoration: const InputDecoration(
                          labelText: "ジャンル（最大三つ）",
                          hintText: "エンターを押すことで追加できます",
                        ),
                        onFieldSubmitted: (text) {
                          model.setGenre(text);
                        },
                      ),
                      const SizedBox(height: 15),

                      // 選択されたジャンルを表示
                      Wrap(
                        runSpacing: 15,
                        spacing: 10,
                        children: model.genres.map((genre) {
                          return InkWell(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(32)),
                            onTap: () {
                              showCupertinoDialog(
                                  context: context,
                                  builder: (_){
                                    return CupertinoAlertDialog(
                                      content: Text("「$genre」を削除しますか？"),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('はい'),
                                          onPressed: () {
                                            model.deleteGenre(genre); // タップされたら削除する
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
                            },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 8),
                                decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(32)),
                                    border: Border.all(
                                        width: 2, color: Colors.blue),
                                    color: Colors.white),
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                        text: genre,
                                        style: const TextStyle(
                                            color: Colors.blue)),
                                    const WidgetSpan(
                                        child: SizedBox(width: 10)),
                                    const WidgetSpan(
                                        child: Icon(
                                      Icons.clear,
                                      size: 17,
                                    )),
                                  ]),
                                )),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 30),

                      // TextButton(onPressed: (){debugPrint(defaultGenre);}, child: Text("テスト"))
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
