import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../common/network_image_utils.dart';
import 'account_switch_providers.dart';
import 'saved_account.dart';
import 'saved_accounts_store.dart';

class AccountSwitchService {
  AccountSwitchService(
    this._store,
    this._ref,
    this._refreshSession,
  );

  final SavedAccountsStore _store;
  final Ref _ref;
  final void Function({int homeTabIndex}) _refreshSession;

  Future<List<SavedAccount>> loadSaved() => _store.load();

  /// 匿名ユーザーを端末の切替一覧に保存する（メールなし）。
  Future<List<SavedAccount>> persistAnonymousAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.isAnonymous) return _store.load();

    final profile = await _fetchUserProfile(user.uid);
    final account = SavedAccount(
      uid: user.uid,
      email: SavedAccount.anonymousPlaceholderEmail(user.uid),
      password: '',
      displayName: profile?['userName'] as String?,
      iconUrl: normalizeNetworkImageUrl(profile?['iconUrl'] as String?),
    );
    return _store.upsert(account);
  }

  Future<List<SavedAccount>> persistAfterAuth({
    required String email,
    required String password,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _store.load();

    final profile = await _fetchUserProfile(user.uid);
    final account = SavedAccount(
      uid: user.uid,
      email: email.trim(),
      password: password,
      displayName: profile?['userName'] as String?,
      iconUrl: normalizeNetworkImageUrl(profile?['iconUrl'] as String?),
    );
    return _store.upsert(account);
  }

  Future<void> refreshCurrentProfileSnapshot() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _fetchUserProfile(user.uid);
    if (profile == null) return;
    await _store.updateProfile(
      uid: user.uid,
      displayName: profile['userName'] as String?,
      iconUrl: normalizeNetworkImageUrl(profile['iconUrl'] as String?),
    );
  }

  Future<List<SavedAccount>> removeFromDevice(String uid) => _store.removeByUid(uid);

  /// ログイン中のアカウントを一覧に載せる（既存ユーザーやホットリロード後用）。
  Future<List<SavedAccount>> ensureCurrentAccountListed() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _store.load();

    if (user.isAnonymous) {
      return persistAnonymousAccount();
    }

    final email = user.email?.trim();
    if (email == null || email.isEmpty) return _store.load();

    final profile = await _fetchUserProfile(user.uid);
    final displayName = profile?['userName'] as String?;
    final iconUrl = normalizeNetworkImageUrl(profile?['iconUrl'] as String?);

    final list = await _store.load();
    if (list.any((a) => a.uid == user.uid)) {
      return _store.updateProfile(
        uid: user.uid,
        displayName: displayName,
        iconUrl: iconUrl,
      );
    }

    return _store.upsert(
      SavedAccount(
        uid: user.uid,
        email: email,
        password: '',
        displayName: displayName,
        iconUrl: iconUrl,
      ),
    );
  }

  Future<void> switchToAccount(
    SavedAccount account, {
    int homeTabIndex = 0,
  }) async {
    final current = FirebaseAuth.instance.currentUser?.uid;
    if (current == account.uid) return;

    final switching = _ref.read(accountSwitchInProgressProvider.notifier);
    switching.set(true);
    try {
      await SchedulerBinding.instance.endOfFrame;
      if (account.isAnonymousPlaceholder) {
        await _signInAnonymousByUid(account.uid);
      } else {
        await _signInAs(account);
      }
      if (account.isAnonymousPlaceholder) {
        await persistAnonymousAccount();
      } else {
        await persistAfterAuth(email: account.email, password: account.password);
      }
      _refreshSession(homeTabIndex: homeTabIndex);
      await SchedulerBinding.instance.endOfFrame;
    } finally {
      switching.set(false);
    }
  }

  Future<void> _signInAnonymousByUid(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createAnonymousSwitchToken',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );
      final result = await callable.call<Map<String, dynamic>>({'uid': uid});
      final raw = result.data;
      final token = (raw['token'] as String?)?.trim();
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(
          code: 'invalid-credential',
          message: '切り替え用トークンを取得できませんでした',
        );
      }
      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithCustomToken(token);
      final signedInUid = FirebaseAuth.instance.currentUser?.uid;
      if (signedInUid != uid) {
        throw FirebaseAuthException(
          code: 'user-mismatch',
          message: 'アカウントの切り替えに失敗しました',
        );
      }
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? '匿名アカウントの切り替えに失敗しました（Functions を確認してください）',
      );
    }
  }

  Future<void> _signInAs(SavedAccount account) async {
    final auth = FirebaseAuth.instance;
    try {
      await auth.signInWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        rethrow;
      }
      await auth.signOut();
      await auth.signInWithEmailAndPassword(
        email: account.email,
        password: account.password,
      );
    }
  }

  Future<Map<String, dynamic>?> _fetchUserProfile(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }
}
