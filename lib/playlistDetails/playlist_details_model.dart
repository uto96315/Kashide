

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaylistDetailsModel extends ChangeNotifier{
  PlaylistDetailsModel(this.playlistId);

  var uid = FirebaseAuth.instance.currentUser?.uid;
  String playlistId;
  List playlistSongs = [];
  bool ready = false;

  Future getPlaylistDetail()async{
    ready = false;
    notifyListeners();

    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists").doc(playlistId)
        .collection("songs").orderBy("addAt");
    final snapshot = await doc.get();
    final baseSongs = snapshot.docs.map((song) {
      return {
        "id": song.id,
        "artist": song["artist"],
        "postId": song["postId"],
        "singName": song["singName"],
        "youtubeUrl": song["youtubeUrl"],
        "addAt": song["addAt"],
        "lyricText": "",
      };
    }).toList();

    playlistSongs = await Future.wait(baseSongs.map(_attachLyricFromPost));
    ready = true;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _attachLyricFromPost(Map<String, dynamic> song) async {
    final postId = song['postId'] as String?;
    if (postId == null || postId.isEmpty) return song;
    try {
      final post = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      final data = post.data();
      if (data == null) return song;
      return {
        ...song,
        'lyricText': data['text'] ?? '',
      };
    } catch (_) {
      return song;
    }
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
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print(e.toString());
    }
  }
}