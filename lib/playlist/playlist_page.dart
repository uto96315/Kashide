import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/editPost/edit_post_page.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/playlist/playlist_model.dart';
import 'package:str_gram_beta/playlistDetails/playlist_details_page.dart';
import 'package:str_gram_beta/post/post_page.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import '../common/ThemeColor.dart';
import '../element/favorite/favorite_button.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlaylistModel>(
        create: (_) => PlaylistModel()..getPlaylists(), // todo: ここでuserDataを取得してからじゃないとプレイリストが描画されない理由がわからない
        child: Consumer<PlaylistModel>(builder: (context, model, child){
          return Scaffold(
            appBar: AppBar(
              title: const Text("プレイリスト"),
              backgroundColor: mainColor,
            ),

            body: RefreshIndicator(  // 下にスワイプでリフレッシュ
              color: mainColor,
              onRefresh: ()async{
                await model.getPlaylists();
                debugPrint("更新しました");
              },
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height,
                  child: Consumer<PlaylistModel>(builder: (context, model, child) {
                    return Column(children: [
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          for(final playlist in model.playlists)
                            GestureDetector(
                              onTap: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>PlaylistDetailsPage(playlist["id"], playlist["playlistName"])));
                              },
                              child: Container(
                                width: MediaQuery.of(context).size.width,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide( color: Colors.grey.shade300 ),
                                  )
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only( top: 20, bottom: 20 ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const SizedBox( width: 30 ),
                                          const Icon( Icons.list, color: Colors.grey ),
                                          const SizedBox( width: 15 ),
                                          Text(playlist["playlistName"], style: const TextStyle( fontSize: 15 )),
                                        ],
                                      ),

                                      IconButton(
                                          onPressed: ()async{
                                            showDialog(context: context, builder: (_){
                                              return CupertinoAlertDialog(
                                                title: const Text("プレイリストの削除"),
                                                content: Text("「${playlist["playlistName"]}」\nを削除しますか？"),
                                                actions: [
                                                  CupertinoDialogAction(
                                                    child: const Text("はい"),
                                                    onPressed: ()async{
                                                      await model.deletePlaylist(playlist["id"]);
                                                      Navigator.pop(context);
                                                    }
                                                  ),
                                                  CupertinoDialogAction(
                                                    child: const Text("いいえ"),
                                                    onPressed: (){
                                                      Navigator.pop(context);
                                                    }
                                                  ),
                                                ],
                                              );
                                            });
                                          },
                                          icon: const Icon(Icons.delete, color: Colors.grey)
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                           const SizedBox( height: 20 ),


                          TextButton(
                              onPressed: (){
                                 model.showAddPlaylistTextFiled();
                                 showDialog(context: context, builder: (_){
                                   return SimpleDialog(
                                     insetPadding: const EdgeInsets.all(10),
                                     title: const Text("プレイリストを追加する"),
                                     children: [
                                       SimpleDialogOption(
                                         child: SizedBox(
                                             width: MediaQuery.of(context).size.width*0.8,
                                             child: TextField(
                                               autofocus: true,
                                               controller: model.addPlaylistController,
                                               decoration: const InputDecoration(
                                                 hintText: "例）お気に入りの曲"
                                               ),
                                               onChanged: (text){
                                                 model.setNewName(text);
                                               },
                                             ),
                                         ),
                                         // onPressed: () => Navigator.pop(context),
                                       ),
                                       SimpleDialogOption(
                                         child: ElevatedButton(
                                           // 新規追加
                                           onPressed: ()async{
                                             if(model.addPlaylistController.text.isEmpty){
                                               return;
                                             }
                                             try{
                                               await model.addNewPlaylist();
                                             } catch(e) {
                                               print(e.toString());
                                             }
                                             await model.getPlaylists();
                                             model.addPlaylistController.text = "";
                                             Navigator.pop(context);
                                           },
                                           style: ElevatedButton.styleFrom(
                                             backgroundColor: mainColor
                                           ),
                                           child: const Text("追加する"),
                                         ),
                                         onPressed: () => Navigator.pop(context),
                                       ),
                                     ],
                                   );
                                 });
                               },
                               child: Row(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: const [
                                   Icon( Icons.add,color: Colors.blue ),
                                   Text(
                                     "プレイリストを新規作成",
                                     style: TextStyle(
                                       color: Colors.blue,
                                       fontSize: 17,
                                     ),
                                   ),
                                 ],
                               )
                           ),
                        ],
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          );
        })
    );
  }
}
