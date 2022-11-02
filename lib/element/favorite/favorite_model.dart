import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class FavoriteModel extends ChangeNotifier {
  FavoriteModel(this.postId, this.likedCount);

  var uid = FirebaseAuth.instance.currentUser?.uid;

  // いいねしたユーザー一覧を取得してそこに含まれているかどうかで分岐すれば行けるか？
  bool isLiked = false;
  List likedUser = [];
  String? postId;
  int? likedCount;
  int? likedNumber;

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
  Future doLike(String id, int likeCount) async {
    // todo: もし既にいいねしているなら削除する
    if (isLiked) {
      await removeLike(id);
      likedNumber = await getLikedCount(id);
      likedCount = likedNumber;
      notifyListeners();
      return;
    }


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

    likedNumber = await getLikedCount(id);

    await Future.wait([
      likePost.set({"postId": id, "likedAt": DateTime.now()}),
      // 投稿にいいねを反映する
      postDoc.update({"likedCount": likedNumber! + 1}),
      // 誰がいいねしたのかを反映する
      whoDoc.set({"likedAt": DateTime.now(), "likedUser": uid}),
    ]);

    likedNumber = await getLikedCount(id);
    likedCount =  likedNumber;
    notifyListeners();
  }




  // いいねを外す処理
 Future removeLike(String id) async{
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

   likedNumber = await getLikedCount(id);

   await Future.wait([
     likePost.delete(),
     // 投稿にいいねを反映する
     postDoc.update({"likedCount": likedNumber! - 1}),
     // 誰がいいねしたのかを反映する
     whoDoc.delete(),
   ]);
 }


 // いいね数を取得する処理
  Future getLikedCount(String id) async{
    final doc = FirebaseFirestore.instance.collection("posts").doc(id).collection("likedUsers");
    final data = await doc.get();
    final newLikedCount = data.docs.length;

    return newLikedCount;
  }

  // いいね数を反映する処理
  void reflectLikedCount(int propsLikedCount) {
    likedNumber = propsLikedCount;
    notifyListeners();
  }
}
