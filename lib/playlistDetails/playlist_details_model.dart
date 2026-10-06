

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/post/post_validation.dart';
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

    final enriched = await Future.wait(baseSongs.map(_attachLyricFromPost));
    playlistSongs = enriched.where(_isDisplayable).toList();
    ready = true;
    notifyListeners();
  }

  bool _isDisplayable(Map<String, dynamic> song) {
    final artist = _nonEmpty(song['artist']);
    final singName = _nonEmpty(song['singName']);
    final lyric = _nonEmpty(song['lyricText']);
    return artist != null && singName != null && lyric != null && lyric.length >= postLyricsMinLength;
  }

  String? _nonEmpty(dynamic value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, dynamic>> _attachLyricFromPost(Map<String, dynamic> song) async {
    final postId = song['postId'] as String?;
    if (postId == null || postId.isEmpty) return song;
    try {
      final post = await FirebaseFirestore.instance.collection('posts').doc(postId).get();
      final data = post.data();
      if (data == null) return song;
      final artist = _nonEmpty(song['artist']) ?? _nonEmpty(data['artist']);
      final singName = _nonEmpty(song['singName']) ?? _nonEmpty(data['singName']);
      final lyric = _nonEmpty(data['text']);
      return {
        ...song,
        if (artist != null) 'artist': artist,
        if (singName != null) 'singName': singName,
        if (lyric != null) 'lyricText': lyric,
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