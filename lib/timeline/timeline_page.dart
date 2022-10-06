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
                              child: Column(
                                children: [
                                  // 歌詞
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width*0.9,
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 20),
                                        child: Text(post.text,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(fontSize: 16, height: 1.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // 曲名などのデータ
                                  // todo: 歌手名や曲名をタップでそのセグメントを見に行けるようにする
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text("歌手："),
                                      Text(post.artist),
                                      const SizedBox(width: 20),
                                      const Text("曲名："),
                                      Text(post.singName),
                                      const SizedBox(width: 15),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                )
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
