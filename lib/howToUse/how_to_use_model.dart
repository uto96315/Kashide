

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class HowToUseModel extends ChangeNotifier{
  var uid = FirebaseAuth.instance.currentUser?.uid;
  List questions = [];
  String? selected;

  Future getQuestions() async{
    final doc = FirebaseFirestore.instance.collection("questions");
    final snapshot = await doc.get();
    questions = snapshot.docs.map((question) {
      return {
        "id": question.id,
        "title": question["title"],
        "answer": question["answer"],
        "caution": question["caution"],
        "imageUrl": question["imageUrl"],
      };
    }).toList();
    debugPrint(questions.toString());
    notifyListeners();
  }

  // 質問がタップさせた時の処理
  void setSelected(String id){
    if(selected == "") {
      selected = id;
      print("${id}を選択しました");
    } else {
      selected = "";
      print("選択を解除しました");
    }
    notifyListeners();
  }

  // 質問を閉じるための処理
  void removeSelected(){
    selected = "";
    notifyListeners();
  }
}