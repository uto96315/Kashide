

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

import 'edit_post_model.dart';

class EditPostPage extends StatelessWidget {
  EditPostPage(
      this.postId,
      this.defaultText,
      this.defaultSingerName,
      this.defaultSingName,
      this.defaultGenreList,
      this.explanation,
      this.youtubeLink,
      {super.key});

  String postId; // 投稿のid
  String explanation;
  String defaultText;
  String defaultSingerName;
  String defaultSingName;
  String youtubeLink;
  List defaultGenreList;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditPostModel>(
      create: (_) => EditPostModel(defaultText, defaultSingerName,defaultSingName, defaultGenreList, postId, explanation, youtubeLink)..getDefaultGenres(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: mainColor,
          actions: [
            Consumer<EditPostModel>(builder: (context, model, child) {
              return // 投稿ボタン
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: MaterialButton(
                    color: (model.canPush) ? Colors.white : null,
                    onPressed: (model.canPush)
                        ? () async {
                      await model.updatePost();
                      showCupertinoDialog(
                          context: context,
                          builder: (_){
                            return CupertinoAlertDialog(
                              content: const Text("投稿しました"),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('OK'),
                                  onPressed: () {
                                    Navigator.pushNamed(context, "/home");
                                  },
                                ),
                              ],
                            );
                          }
                      );
                    }
                        : null,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 15, left: 15),
                      child: Text(
                        "編集完了",
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
            child: Consumer<EditPostModel>(builder: (context, model, child) {
              return Column(
                children: [
                  const SizedBox( height: 50 ),

                  // 好きな理由記入欄
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextField(
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
                  ),
                  const SizedBox(height: 15),

                  // 歌詞
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextField(
                      controller: model.postLyricsController,
                      maxLines: null,
                      maxLength: 300,
                      decoration: InputDecoration(
                        labelText: "心に響いた歌詞を入力しましょう(必須)",
                          suffixIcon: IconButton(
                              onPressed: (){
                                model.pasteText(model.postLyricsController); // todo: チェックこれ何
                              },
                              icon: const Icon(Icons.paste)
                          )
                      ),
                      onChanged: (text) {
                        model.setLyrics(text);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 歌手名入力欄
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextField(
                      controller: model.postSingerController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: "歌手名(任意)",
                          suffixIcon: IconButton(
                              onPressed: (){
                                model.pasteText(model.postSingerController);
                              },
                              icon: const Icon(Icons.paste)
                          )
                      ),
                      onChanged: (text) {
                        model.setSinger(text);
                      },
                    ),
                  ),

                  const SizedBox(height: 15),

                  // 曲名入力欄
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextField(
                      controller: model.postSingNameController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: "曲名(任意)",
                          suffixIcon: IconButton(
                              onPressed: (){
                                model.pasteText(model.postSingNameController);
                              },
                              icon: const Icon(Icons.paste)
                          )
                      ),
                      onChanged: (text) {
                        model.setSing(text);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),


                  // Youtubeなどのリンクを貼る
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextField(
                      controller: model.youtubeLinkController,
                      maxLines: 1,
                      maxLength: 200,
                      decoration: InputDecoration(
                        labelText: "Youtubeリンク",
                          suffixIcon: IconButton(
                              onPressed: (){
                                // model.pasteText(model.youtubeLinkController);
                              },
                              icon: const Icon(Icons.paste)
                          )
                      ),
                      onChanged: (text){
                        model.setYoutubeLink(text);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),


                  // デフォルトジャンルリスト
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: Row(
                      children: const [
                        Text("ジャンル(タップで選択)", style: TextStyle( fontSize: 17, color: Colors.black54 ),),
                        SizedBox( width: 10 ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: Row(
                      children: const [
                        Text("※最大三つまで", style: TextStyle( fontSize: 12, color: Colors.black54 )),
                        SizedBox( width: 10 ),
                      ],
                    ),
                  ),
                  const SizedBox( height: 20 ),

                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: Wrap(
                      runSpacing: 15,
                      spacing: 10,
                      children: [
                        for(final genre in model.defaultGenresList)
                          InkWell(
                            onTap: (){
                              if(model.selectedGenreList.contains(genre)) {
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
                                    (model.selectedGenreList.contains(genre)) ? mainColor : Colors.blue),
                                    color: Colors.white),
                                child: RichText(
                                  text: TextSpan(children: [
                                    TextSpan(
                                        text: genre,
                                        style: TextStyle(
                                            color: model.selectedGenreList.contains(genre) ? mainColor : Colors.blue)
                                    ),
                                  ]),
                                )),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox( height: 30 ),

                  // ジャンル追加欄
                  SizedBox(
                    width: MediaQuery.of(context).size.width*0.8,
                    child: TextFormField(
                      controller: model.genreController,
                      enabled: model.genreMaxLength,
                      maxLength: 15,
                      decoration: const InputDecoration(
                        labelText: "ジャンルを追加する",
                        hintText: "エンターを押すことで追加できます",
                      ),
                      onFieldSubmitted: (text) {
                        model.setGenre(text);
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}