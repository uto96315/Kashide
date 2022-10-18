import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/element/comment/comment_area.dart';
import 'package:str_gram_beta/element/favorite/favorite_button.dart';
import 'package:str_gram_beta/postDetail/post_detail_model.dart';

class PostDetailPage extends StatelessWidget {
  PostDetailPage(this.id, this.commentButtonTapped, {super.key});

  String id;
  bool commentButtonTapped;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostDetailModel>(
        create: (_) => PostDetailModel(id, commentButtonTapped)
          ..getPost(id)
          ..getUserData(),
        child: Consumer<PostDetailModel>(builder: (context, model, child) {
          return GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: Scaffold(
              appBar: AppBar(
                backgroundColor: mainColor,
              ),
              body: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Center(
                        child: Consumer<PostDetailModel>(
                            builder: (context, model, child) {
                          return Column(
                            children: [
                              const SizedBox(height: 30),

                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 20, left: 20),
                                child: Row(
                                  children: [
                                    // 画像
                                    Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey),
                                          borderRadius: BorderRadius.circular(50),
                                          color: Colors.grey.shade200,
                                          image: (model.userIconUrl != null ||
                                                  model.userIconUrl != "")
                                              ? DecorationImage(
                                                  image: NetworkImage(model.userIconUrl ?? ""), fit: BoxFit.cover)
                                              : null,
                                        ),
                                        child: (model.userIconUrl != "")
                                            ? null
                                            : const Icon(Icons.person)),
                                    const SizedBox(width: 10),

                                    // 名前
                                    Text(model.posterName ?? "読み込み中...",
                                        style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // 本文
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 20, left: 20),
                                child: Text(model.postText ?? "読み込み中...",
                                    style: const TextStyle(
                                        fontSize: 16, height: 1.5)),
                              ),
                              const SizedBox(height: 20),

                              // ジャンル一覧
                              Wrap(
                                runSpacing: 15,
                                spacing: 10,
                                children: model.genreList
                                    .map((genre) => Container(
                                          decoration: BoxDecoration(
                                            border:
                                                Border.all(color: Colors.blue),
                                            borderRadius:
                                                BorderRadius.circular(100),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Text(
                                              genre,
                                              style: const TextStyle(
                                                  color: Colors.blue),
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),

                              const SizedBox(height: 20),

                              Padding(
                                padding: const EdgeInsets.only(right: 20),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    const Text("歌手：",
                                        style: TextStyle(fontSize: 11)),
                                    Text(model.singerName ?? "読み込み中",
                                        style: const TextStyle(fontSize: 11)),
                                    const SizedBox(width: 10),
                                    const Text("曲名：",
                                        style: TextStyle(fontSize: 11)),
                                    Text(model.singName ?? "読み込み中",
                                        style: const TextStyle(fontSize: 11)),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Divider(
                                color: Colors.black54,
                              ),


                              // コメント一覧
                              SizedBox(
                                  width: MediaQuery.of(context).size.width,
                                  height: MediaQuery.of(context).size.height*20, // todo: 無限にしたい
                                  child: CommentArea(id)),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),

                  // 下段のコメント入力欄
                  Padding(
                    padding:
                        const EdgeInsets.only(right: 10, left: 10, bottom: 10),
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Row(
                        children: [
                          Container(
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width * 0.1,
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(100),
                                  color: Colors.grey.shade200,
                                  image: (model.userImageUrl != null || model.userImageUrl != "")
                                      ? DecorationImage(image: NetworkImage(model.userImageUrl ?? ""), fit: BoxFit.cover)
                                      : null,
                              ),
                              child: (model.userImageUrl == null || model.userImageUrl == "")
                                  ? const Icon(Icons.person)
                                  : null
                          ),

                          SizedBox(
                              width: MediaQuery.of(context).size.width * 0.03),

                          // テキストフィールド
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: TextField(
                              controller: model.commentController,
                              maxLength: 200,
                              maxLines: null,
                              decoration: InputDecoration(
                                  fillColor: Colors.red,
                                  hintText: "素敵なコメントを入力",
                                  counterText: model.counterTextVisible
                                      ? null
                                      : "", // カウンターの可視不可視
                                  enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: const BorderSide(
                                          color: Colors.grey))),
                              onChanged: (text) {
                                model.showCount(text); // カウントを表示する
                                model.checkComment(text);
                              },
                            ),
                          ),

                          // 送信ボタン
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.05,
                            child: CupertinoButton(
                                onPressed: model.canComment
                                    ? () async {
                                        model.showCount(
                                            model.commentController.text);
                                        await model.addComment(id);
                                        model.commentController.text = "";
                                        FocusScope.of(context).unfocus();
                                      }
                                    : null,
                                child: Icon(Icons.send, color: model.canComment ? Colors.blue : Colors.grey)),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }));
  }
}
