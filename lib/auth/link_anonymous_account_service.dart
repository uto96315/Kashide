import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LinkAnonymousAccountException implements Exception {
  LinkAnonymousAccountException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LinkAnonymousAccountService {
  Future<void> linkEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw LinkAnonymousAccountException('ログイン状態を確認できませんでした。');
    }
    if (!user.isAnonymous) {
      throw LinkAnonymousAccountException('このアカウントはすでにメールアドレスが登録されています。');
    }

    final trimmedEmail = email.trim();
    try {
      final credential = EmailAuthProvider.credential(
        email: trimmedEmail,
        password: password,
      );
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw LinkAnonymousAccountException(_messageFor(e));
    }

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
      {'email': trimmedEmail},
      SetOptions(merge: true),
    );
  }

  String _messageFor(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'このメールアドレスはすでに使われています。';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません。';
      case 'weak-password':
        return 'パスワードは6文字以上にしてください。';
      case 'credential-already-in-use':
        return 'このメールアドレスは別のアカウントに紐づいています。';
      case 'operation-not-allowed':
        return 'メールアドレスでの登録が有効になっていません。';
      default:
        return e.message ?? 'メールアドレスの登録に失敗しました。';
    }
  }
}
