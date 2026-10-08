import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

    _ref.read(accountSwitchInProgressProvider.notifier).set(true);
    try {
      await _signInAs(account);
      await persistAfterAuth(email: account.email, password: account.password);
      _refreshSession(homeTabIndex: homeTabIndex);
    } finally {
      _ref.read(accountSwitchInProgressProvider.notifier).set(false);
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
