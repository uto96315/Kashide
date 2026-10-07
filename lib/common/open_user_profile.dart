import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/providers.dart';

/// 自分ならマイページ、他人ならプロフィール（投稿一覧）へ。
void openUserProfile(
  BuildContext context, {
  required String posterId,
  String? userName,
}) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null && uid == posterId) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPage()));
    return;
  }
  final blocked = ProviderScope.containerOf(context).read(blockListProvider).isBlocked(posterId);
  if (blocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ブロック中のユーザーです')),
    );
    return;
  }
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => GenrePage(posterId, 'poster', title: userName)),
  );
}
