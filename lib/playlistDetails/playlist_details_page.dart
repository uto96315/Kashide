

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/playlistDetails/playlist_details_model.dart';

class PlaylistDetailsPage extends StatelessWidget {
  PlaylistDetailsPage(this.playlistId, this.playlistName, {super.key});
  String playlistId;
  String playlistName;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PlaylistDetailsModel>(
      create: (_) => PlaylistDetailsModel(playlistId)..getPlaylistDetail(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(playlistName, style: TextStyle( fontSize: 16 )),
          backgroundColor: mainColor,
        ),
        body: Center(
          child: Consumer<PlaylistDetailsModel>(builder: (context, model, child) {
            return Center(
              child: Column(
                children: [
                  for(final song in model.playlistSongs)
                    Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide( color: Colors.grey.shade300 )
                          )
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only( top: 10, bottom: 10 ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const SizedBox( width: 20 ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(song["singName"], style: const TextStyle( fontSize: 17, fontWeight: FontWeight.bold )),
                                      Text(song["artist"]),
                                    ],
                                  ),
                                ],
                              ),


                              Row(
                                children: [

                                  // youtubeへのリンクボタン
                                  song["youtubeUrl"] != "" ?
                                  IconButton(
                                    icon: const Icon(Icons.play_circle, color: Colors.red, size: 30 ),
                                    onPressed: ()async{
                                      await model.launchURL(song["youtubeUrl"]);
                                    },
                                  ) : const Text(""),

                                  // 削除ボタン
                                  IconButton(
                                      onPressed: ()async{
                                        showDialog(context: context, builder: (_){
                                          return CupertinoAlertDialog(
                                            title: const Text("プレイリストから削除"),
                                            content: Text("「${song["singName"]}」をこのプレイリストから削除しますか？"),
                                            actions: [
                                              CupertinoDialogAction(
                                                  child: const Text("はい"),
                                                  onPressed: ()async{
                                                    await model.deleteFromPlaylist(song["id"]);
                                                    Navigator.pop(context);
                                                  },
                                              ),
                                              CupertinoDialogAction(
                                                  child: const Text("いいえ"),
                                                  onPressed: (){
                                                    Navigator.pop(context);
                                                  },
                                              ),
                                            ],
                                          );
                                        });
                                      },
                                      icon: const Icon(Icons.delete, color: Colors.grey )
                                  ),
                                ],
                              ),
                            ],
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