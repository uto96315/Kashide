

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class PostDetailModel extends ChangeNotifier {
  PostDetailModel(id);

  var uid = FirebaseAuth.instance.currentUser?.uid;

  // 投稿関係
  String? text;
  String? posterId;
  String? singName;
  String? singerName;
  List genreList = [];

  // 投稿者関係
  String? posterName;
  String? userIconUrl;


  // 投稿の詳細取得
  Future getPost(String id) async{
    final doc = FirebaseFirestore.instance.collection("posts").doc(id);

    final snapshot = await doc.get();
    final data = snapshot.data();

    text = data?["text"];
    posterId = data?["posterId"];
    singName = data?["singName"];
    singerName = data?["artist"];
    genreList = data?["genres"];

    await getPosterData(posterId ?? "");

    notifyListeners();
  }

  // 投稿者の取得
  Future getPosterData(String id) async{
    final doc = FirebaseFirestore.instance.collection("users").doc(id);

    final snapshot = await doc.get();
    final data = snapshot.data();

    posterName = data?["userName"] ?? "";
    userIconUrl = data?["iconUrl"] ?? "";
    notifyListeners();
  }
}