import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';



class SearchModel extends ChangeNotifier {
   var uid = FirebaseAuth.instance.currentUser?.uid;
   final searchTextController = TextEditingController();

   Map<String, List<dynamic>> wordObject = {
      // "あなたにおすすめ": ["recommend", recommendColor],
      "恋愛ソング": ["loveSong", loveColor],
      "失恋ソング": ["lostLoveSong", lostLoveColor],
      "元気が出る歌": ["energySong", energyColor],
      "懐メロ": ["", recommendColor],
   };

   // 変数関係
   String? searchText; // 検索されたワード
   String? userName;
   List<String> defaultGenresList = [
      "恋愛ソング",
      "懐メロ",
      "JPOP",
      "男性目線",
      "女性目線",
      "LGBTQ",
      "洋楽",
      "失恋ソング",
      "人生",
      "ロック",
      "ジャニーズ",
      "元気になれる曲",
      "R&B ソウル",
      "アイドル",
      "青春",
      "勇気",
      "その他",
      "ペット",
   ];



   // ここから処理関係

   void setText(String text){
      if(text.isEmpty) {
         return;
      }
      searchText = text;
      notifyListeners();
   }

   void onSearchFieldChanged(String text) {
      searchText = text.isEmpty ? null : text;
      notifyListeners();
   }

   Future searchByText(String text) async{
      print(text);
      notifyListeners();
   }

   Future getUserData() async{
      final doc = FirebaseFirestore.instance
          .collection("users").doc(uid);

      final snapshot = await doc.get();
      final data = snapshot.data();

      userName = data?["userName"];

      notifyListeners();
   }

   // firestoreからジャンルを取得する
   Future getDefaultGenres()async{
      final doc = FirebaseFirestore.instance.collection("genres").doc("defaultGenres");
      final snapshot = await doc.get();
      defaultGenresList = snapshot.data()?["genres"].cast<String>();
      print(defaultGenresList);
      notifyListeners();
   }

   // レビューを促す処理
   void requestReview() {
      final review = InAppReview.instance;
      review.isAvailable().then((available) {
         if (available) {
            review.requestReview();
         }
      });
      notifyListeners();
   }
}

