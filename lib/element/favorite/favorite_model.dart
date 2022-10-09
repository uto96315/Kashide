import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FavoriteModel extends ChangeNotifier {
  FavoriteModel(this.postId, this.likedCount);

  var uid = FirebaseAuth.instance.currentUser?.uid;

  // いいねしたユーザー一覧を取得してそこに含まれているかどうかで分岐すれば行けるか？
  bool isLiked = false; // todo:ここでは初期化したくない この値でアイコンの色が確定されてしまう
  List likedUser = [];
  String? postId;
  int? likedCount;

  // ユーザーが既にその投稿に対していいねしているのか判定する処理
  Future checkLiked() async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        .doc(postId)
        .collection("likedUsers");

    final snapshot = await doc.get();
    likedUser = snapshot.docs.map((doc) => doc["likedUser"]).toList();

    if (likedUser.contains(uid)) {
      isLiked = true;
    } else {
      isLiked = false;
    }
    notifyListeners();
  }

  // いいね処理
  Future doLike(String id, int likedCount) async {
    // todo: もし既にいいねしているなら削除する
    if (isLiked) {
      debugPrint("既にいいねされています");
      return;
    }

    debugPrint("いいねしました");
    // ユーザーにセットする
    // todo: collectionをlikePostsに変更する
    final likePost = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("likePost")
        .doc(id);
    final postDoc = FirebaseFirestore.instance.collection("posts").doc(id);
    final whoDoc = FirebaseFirestore.instance
        .collection("posts")
        .doc(id)
        .collection("likedUsers")
        .doc(uid);

    await Future.wait([
      likePost.set({"postId": id, "likedAt": DateTime.now()}),
      // 投稿にいいねを反映する
      postDoc.update({"likedCount": likedCount + 1}),
      // 誰がいいねしたのかを反映する
      whoDoc.set({"likedAt": DateTime.now(), "likedUser": uid}),
    ]);
    notifyListeners();
  }
}
