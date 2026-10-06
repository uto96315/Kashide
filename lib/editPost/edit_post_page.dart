

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/primary_button.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/song/song_pick_page.dart';
import 'package:str_gram_beta/song/song_quote.dart';

class EditPostPage extends ConsumerWidget {
  const EditPostPage(
      this.postId,
      this.defaultText,
      this.defaultSingerName,
      this.defaultSingName,
      this.defaultGenreList,
      this.explanation,
      this.youtubeLink,
      {super.key});

  final String postId;
  final String explanation;
  final String defaultText;
  final String defaultSingerName;
  final String defaultSingName;
  final String youtubeLink;
  final List defaultGenreList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(editPostProvider(EditPostArgs(
      postId: postId,
      defaultText: defaultText,
      defaultSingerName: defaultSingerName,
      defaultSingName: defaultSingName,
      defaultGenreList: defaultGenreList,
      explanation: explanation,
      youtubeLink: youtubeLink,
    )));
    return Scaffold(
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: PrimaryButton(
              label: '編集完了',
              onPressed: model.canPush
                  ? () async {
                      await model.updatePost();
                      if (!context.mounted) return;
                      await ref.read(timelineProvider).getFirstPostData();
                      ref.invalidate(myPageProvider);
                      if (!context.mounted) return;
                      final messenger = ScaffoldMessenger.of(context);
                      Navigator.pop(context);
                      messenger.showSnackBar(const SnackBar(content: Text('更新しました')));
                    }
                  : null,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
                children: [
                  const ScreenTop(),

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
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () async {
                      final quote = await Navigator.push<SongQuote>(
                        context,
                        MaterialPageRoute(builder: (_) => const SongPickPage()),
                      );
                      if (quote != null) model.applyQuote(quote);
                    },
                    icon: const Icon(Icons.library_music),
                    label: const Text('曲と歌詞の範囲を選び直す'),
                  ),
                  const SizedBox(height: 8),

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
              ),
          ),
        ),
      );
  }
}