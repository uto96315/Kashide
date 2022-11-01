
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../element/favorite/favorite_button.dart';
import '../../postDetail/post_detail_page.dart';
import 'lyrics_search_model.dart';



class LyricsSearchPage extends StatelessWidget {
  LyricsSearchPage(this.searchWord, {super.key});
  String searchWord;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LyricsSearchModel>(
      create: (_) => LyricsSearchModel(searchWord)..searchFromLyrics(searchWord),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            child: Consumer<LyricsSearchModel>(builder: (context, model, child) {
              return Column(
                children: [
                  const SizedBox( height: 30 ),
                  Text(model.lyricsResultCount > 0
                      ? "全部で${model.lyricsResultCount}件の投稿が見つかりました。"
                      : "投稿が見つかりませんでした。"
                  ),
                  const SizedBox(height: 10),
                  const Divider( color: Colors.grey ),


                  Column(
                    // Listから生成-----------------------------------------------
                    children: model.lyricsResultList.map((result){
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
                                    image: (result.userImageUrl != "")
                                        ? DecorationImage(
                                        image: NetworkImage(
                                            result.userImageUrl),
                                        fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (result.userImageUrl != "")
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
                                            Text(result.userName),
                                          ],
                                        ),
                                        const SizedBox( width: 10 ),
                                        Text(result.createdAt, style: const TextStyle( color: Colors.grey )),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 50),

                                  // 説明
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width*0.8,
                                    child: Text(
                                        result.explanation,
                                        textAlign: TextAlign.left,
                                        style: const TextStyle( fontSize: 15, height: 1.5)
                                    ),
                                  ),

                                  const SizedBox( height: 10 ),

                                  // 歌詞
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: Colors.grey.shade200
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text("---\n${result.text}\n---",
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                                fontSize: 16, height: 1.5)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),


                                  // ジャンル一覧
                                  SizedBox(
                                    width: MediaQuery.of(context).size.width*0.8,
                                    child: Wrap(
                                      runSpacing: 15,
                                      spacing: 10,
                                      children: result.genres.map((genre) =>
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all( color: Colors.blue),
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(10.0),
                                              child: Text(genre, style: const TextStyle( color: Colors.blue)),
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
                                          children: [
                                            Row(
                                              children: [
                                                const Text("歌手：", style: TextStyle( fontSize: 11)),
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                      result.artist,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle( fontSize: 11, color: Colors.black )
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height:5),
                                            Row(
                                              children: [
                                                const Text("曲名：", style: TextStyle( fontSize: 11)),
                                                SizedBox(
                                                  width: 100,
                                                  child: Text(
                                                      result.singName,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle( fontSize: 11, color: Colors.black)
                                                  ),
                                                ),
                                              ],
                                            ),
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
                                            child: result.youtubeLink != ""
                                                ? CupertinoButton(
                                                minSize: double.minPositive,
                                                padding: EdgeInsets.zero,
                                                onPressed: (){
                                                  launchUrl(Uri.parse(result.youtubeLink));
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
                                                Navigator.push(context, MaterialPageRoute(builder: (context) => PostDetailPage(result.id, true)));
                                              },
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.comment, color: Colors.grey ),
                                                  const SizedBox( width: 5 ),
                                                  Text(result.commentCount.toString() ?? "", style: const TextStyle( fontSize: 17 )),
                                                ],
                                              )
                                          ),
                                          const SizedBox( width: 20 ),
                                          SizedBox(
                                              width: 50,
                                              height: 30,
                                              child: FavoriteButton(result.id, result.likedCount)
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
                    }).toList(),
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