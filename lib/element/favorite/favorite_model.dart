import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FavoriteModel extends ChangeNotifier {
  FavoriteModel(this.postId, this.likedCount);

  var uid = FirebaseAuth.instance.currentUser?.uid;
  // いいねしたユーザー一覧を取得してそこに含まれているかどうかで分岐すれば行けるか？
  bool isLiked = false;  // todo:ここでは初期化したくない この値でアイコンの色が確定されてしまう
  List likedUser = [];
  String? postId;
  int? likedCount;


  // ユーザーが既にその投稿に対していいねしているのか判定する処理
  Future checkLiked() async{

    final doc = FirebaseFirestore.instance.collection("posts")
        .doc(postId).collection("likedUsers");

    final snapshot = await doc.get();
    likedUser = snapshot.docs.map((doc) =>
    doc["likedUser"]
    ).toList();

    if(likedUser.contains(uid)) {
      isLiked = true;
    } else {
      isLiked = false;
    }
  }



  // いいね処理
  Future doLike(String id, int likedCount) async{
    // todo: もし既にいいねしているなら削除する
    if(isLiked) {
      debugPrint("既にいいねされています");
      return;
    } else {
      debugPrint("いいねしました");
      // ユーザーにセットする
      final userDoc = FirebaseFirestore.instance.collection("users")
          .doc(uid).collection("likePost").doc(id);

      await userDoc.set({
        "postId": id,
        "likedAt": DateTime.now()
      });


      // 投稿にいいねを反映する
      final postDoc = FirebaseFirestore.instance.collection("posts").doc(id);

      await postDoc.update({
        "likedCount": likedCount + 1
      });


      // 誰がいいねしたのかを反映する
      final whoDoc = FirebaseFirestore.instance
          .collection("posts").doc(id).collection("likedUsers").doc(uid);

      await whoDoc.set({
        "likedAt": DateTime.now(),
        "likedUser": uid
      });
    }
  }
}