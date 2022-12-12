

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistDetailsModel extends ChangeNotifier{
  PlaylistDetailsModel(this.playlistId);

  var uid = FirebaseAuth.instance.currentUser?.uid;
  String playlistId;
  List playlistSongs = [];

  Future getPlaylistDetail()async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists").doc(playlistId)
        .collection("songs").orderBy("addAt");
    final snapshot = await doc.get();
    playlistSongs = snapshot.docs.asMap().entries.map((song) {
      return {
        "id": song.value.id,
        "artist": song.value["artist"],
        "postId": song.value["postId"],
        "singName": song.value["singName"],
        "youtubeUrl": song.value["youtubeUrl"],
        "addAt": song.value["addAt"],
      };
    }).toList();

    notifyListeners();
  }

  // プレイリストから削除する処理
  Future deleteFromPlaylist(String songId)async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists").doc(playlistId)
        .collection("songs").doc(songId);

    try {await doc.delete();} catch(e) { print(e.toString()); }
    await getPlaylistDetail();
    notifyListeners();
  }

  // Youtubeアプリを開く処理
  Future launchURL(String url) async {
    try {
      if (await canLaunch(url)) {
        await launch(
          url,
          forceSafariVC: false,
        );
      }
    } catch(e) {
      print(e.toString());
    }
  }
}