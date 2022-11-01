import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:timeago/timeago.dart' as timeAgo;


class SearchResultModel extends ChangeNotifier {
  SearchResultModel(this.searchWord);
  

  String? searchWord;

  List<Post> genreResultList= []; // ジャンル検索に引っかかった投稿
  List<Post> singerResultList= []; // 歌手検索に引っかかった投稿


  int genreResultCount = 0; // ジャンル結果の総数
  int singerResultCount = 0; // 歌手結果の総数


  // 表示するタブのリストを作成
  final List<Tab> tabs = <Tab>[
    const Tab(text: 'tab1'),
    const Tab(text: 'tab2'),
    const Tab(text: 'tab3'),
  ];



  // ジャンルから探す処理=========================
  Future searchFromGenre(String searchWord) async{
    final genreCollection = FirebaseFirestore.instance
        .collection("posts")
        .where("genres", arrayContains: searchWord);

    final snapshot = await genreCollection.get();

    // ユーザー情報の取得
    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    // コメント数の取得
    final commentCount = await Future.wait(
        snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );


    // ここで合体
    genreResultList = snapshot.docs.asMap().entries.map((entry){
      int index = entry.key;
      final postData = entry.value;

      return Post(
          postData["artist"],
          postData["singName"],
          postData["text"],
          postData["posterId"],
          postData["likedCount"],
          postData["genres"],
          "${userInfo[index][0]}",
          "${userInfo[index][1]}",
          createTimeMessage(postData["createdAt"].toDate()),
          postData.id,
          commentCount[index] ?? 0,
          postData["explanation"],
          postData["youtubeLink"],
      );
    }).toList();
    genreResultCount = genreResultList.length;
    notifyListeners();
  }
  // ジャンルから探す処理=========================


  // 歌手から探す処理=========================
  Future searchFromSinger(String searchWord) async{
    final genreCollection = FirebaseFirestore.instance
        .collection("posts")
        .where("artist", arrayContains: searchWord);

    final snapshot = await genreCollection.get();

    // ユーザー情報の取得
    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    // コメント数の取得
    final commentCount = await Future.wait(
        snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );


    // ここで合体
    singerResultList = snapshot.docs.asMap().entries.map((entry){
      int index = entry.key;
      final postData = entry.value;

      return Post(
        postData["artist"],
        postData["singName"],
        postData["text"],
        postData["posterId"],
        postData["likedCount"],
        postData["genres"],
        "${userInfo[index][0]}",
        "${userInfo[index][1]}",
        createTimeMessage(postData["createdAt"].toDate()),
        postData.id,
        commentCount[index] ?? 0,
        postData["explanation"],
        postData["youtubeLink"],
      );
    }).toList();
    singerResultCount = genreResultList.length;
    notifyListeners();
  }
  // 歌手から探す処理=========================



  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }

  // ユーザー情報を取得する関数
  Future getUserData(String uid) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final userName = data?["userName"];
    final userImageUrl = data?["iconUrl"];
    notifyListeners();
    return [userName, userImageUrl];
  }

  // コメント数の取得
  Future getCommentCount(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id).collection("comments");
    final snapshot = await doc.get();
    final count = snapshot.docs.length;

    return count;
  }

}