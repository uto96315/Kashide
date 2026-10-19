

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/playlist/default_playlists.dart';

class PlaylistModel extends ChangeNotifier {
  final addPlaylistController = TextEditingController();

  @override
  void dispose() {
    addPlaylistController.dispose();
    super.dispose();
  }

  var uid = FirebaseAuth.instance.currentUser?.uid;
  List playlists = [];
  bool ready = false;
  List options = ["あああ", "いいい"];
  bool showAddPlaylistTextField = false;
  String? newPlaylistName;

  // ユーザー情報を取得する関数
  Future getUserData() async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final userName = data?["userName"];
    final userImageUrl = data?["iconUrl"];
    notifyListeners();
    return [userName, userImageUrl];
  }

  // プレイリストを取得する
  Future getPlaylists()async{
    uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      playlists = [];
      ready = true;
      notifyListeners();
      return;
    }
    await DefaultPlaylists.ensureForUser(uid!);

    final doc = FirebaseFirestore.instance.collection("users")
        .doc(uid).collection("playlists");
    final snapshot = await doc.get();

    playlists = snapshot.docs.asMap().entries.map((playlist) {
      final data = playlist.value.data();
      return {
        "id": playlist.value.id,
        "playlistName": data["playlistName"],
        "systemKey": data["systemKey"],
      };
    }).toList();
    ready = true;
    notifyListeners();

    print(playlists);
  }

  // テキストフィールドの値を取得
  void setNewName(String text){
    newPlaylistName = text;
    notifyListeners();
  }
  // プレイリストを追加する
  Future addNewPlaylist()async{
    newPlaylistName = addPlaylistController.text;
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists");
    await doc.add({
      "createdAt": DateTime.now(),
      "playlistName": newPlaylistName,
    });
    notifyListeners();
  }

  // プレイリストを削除する
  Future deletePlaylist(String id)async{
    for (final p in playlists) {
      if (p is! Map) continue;
      if (p['id'] != id) continue;
      if (DefaultPlaylists.isSystemPlaylist(p['systemKey'] as String?)) {
        return;
      }
      break;
    }
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists").doc(id);
    await doc.delete();
    await getPlaylists();
    notifyListeners();
  }

  // プレイリスト追加画面を表示する
  void showAddPlaylistTextFiled(){
    showAddPlaylistTextField = true;
    notifyListeners();
  }
}