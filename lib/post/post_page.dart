import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/post/post_model.dart';

class PostPage extends StatelessWidget {
  const PostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostModel>(
      create: (_) => PostModel(),
      child: Scaffold(
        appBar: AppBar(title: const Icon(Icons.edit)),
        body: Center(
          child: Consumer<PostModel>(builder: (context, model, child) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // お気に入りの歌詞入力欄
                  TextField(
                    controller: model.lyricsController,
                    maxLines: 3,
                    maxLength: 300,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: "心に響いた歌詞を入力しましょう(必須)",
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
                    autofocus: true,
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


                  // 投稿ボタン
                  ElevatedButton(
                      onPressed: () async {
                        await model.post();
                        Navigator.pushNamed(context, "/home");
                      },
                      child: const Padding(
                        padding: EdgeInsets.only(
                            top: 10, bottom: 10, left: 50, right: 50),
                        child: Text(
                          "投稿",
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      )
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
