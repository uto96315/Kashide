import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'timeline_model.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TimelineModel>(
      create: (_) => TimelineModel()..getPosts(),
      child: Scaffold(
        appBar: AppBar(
          title: const Icon(Icons.tag),
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<TimelineModel>(builder: (context, model, child) {
              return Column(children: [
                const SizedBox(height: 10),
                Column(
                  children: model.postsList
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
                                            MediaQuery.of(context).size.width *
                                                0.8,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                SizedBox(width: 15),
                                                Text(post.userName),
                                              ],
                                            ),
                                            Text(post.createdAt, style: const TextStyle( color: Colors.grey )),
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

                                      SizedBox(
                                        width: MediaQuery.of(context).size.width*0.8,
                                        child: Wrap(
                                          runSpacing: 15,
                                          spacing: 10,
                                          children: post.genres.map((genre) =>
                                              Container(
                                                decoration: BoxDecoration(
                                                    border: Border.all( color: Colors.blue ),
                                                  borderRadius: BorderRadius.circular(100),
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child: Text(genre, style: const TextStyle( color: Colors.blue ),),
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
                                            Text(post.artist, style: const TextStyle( fontSize: 11)),
                                            const SizedBox(width: 20),
                                            const Text("曲名：", style: TextStyle( fontSize: 11)),
                                            Text(post.singName, style: const TextStyle( fontSize: 11)),
                                            const SizedBox(width: 15),
                                          ],
                                        ),
                                      ),

                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ]);
            }),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, "/post");
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
