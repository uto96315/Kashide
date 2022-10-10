import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

import '../../element/favorite/favorite_model.dart';

class FavoriteButton extends StatelessWidget {
  FavoriteButton(this.postId, this.likedCount);
  String postId;
  int? likedCount;
  var uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FavoriteModel>(
      create: (_) => FavoriteModel(postId, likedCount)..checkLiked(),
      child: Scaffold(
        body: Center(
          child: Consumer<FavoriteModel>(builder: (context, model, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 10),
                CupertinoButton(
                  minSize: double.minPositive,
                  padding: EdgeInsets.zero,

                  onPressed: ()async{
                    await model.doLike(postId, likedCount!);
                    await model.checkLiked();
                  },
                    child: Row(
                      children: [
                        Icon(Icons.favorite, color: model.isLiked ? mainColor : Colors.grey),
                        const SizedBox( width: 5 ),
                        Text(model.likedCount.toString(), style: const TextStyle(fontSize: 17, color: Colors.black)),
                      ],
                    ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}