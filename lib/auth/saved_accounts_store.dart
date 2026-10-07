import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'saved_account.dart';

const _storageKey = 'kashide_saved_accounts_v1';
const maxSavedAccounts = 20;

/// ログイン情報を Keychain / Keystore に保存する。
class SavedAccountsStore {
  SavedAccountsStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<List<SavedAccount>> load() async {
    final raw = await _storage.read(key: _storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final parsed = list
          .map((e) => SavedAccount.fromJson(Map<String, dynamic>.from(e as Map)))
          .whereType<SavedAccount>()
          .toList();
      return _dedupeByUid(parsed);
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<SavedAccount> accounts) async {
    final encoded = jsonEncode(accounts.map((a) => a.toJson()).toList());
    await _storage.write(key: _storageKey, value: encoded);
  }

  /// ログイン成功後に呼ぶ。同じ uid は上書きし、先頭に移動する。
  static List<SavedAccount> _dedupeByUid(List<SavedAccount> accounts) {
    final map = <String, SavedAccount>{};
    for (final a in accounts) {
      final prev = map[a.uid];
      if (prev == null) {
        map[a.uid] = a;
        continue;
      }
      // パスワード付き（切替可能）を優先して残す。
      if (a.password.isNotEmpty && prev.password.isEmpty) {
        map[a.uid] = a;
      }
    }
    return map.values.toList();
  }

  Future<List<SavedAccount>> upsert(SavedAccount account) async {
    final current = await load();
    final existing = current.where((a) => a.uid == account.uid).firstOrNull;
    final merged = account.copyWith(
      password: account.password.isNotEmpty ? account.password : (existing?.password ?? ''),
      displayName: account.displayName ?? existing?.displayName,
      iconUrl: account.iconUrl ?? existing?.iconUrl,
    );
    final without = current.where((a) => a.uid != account.uid).toList();
    final next = [merged, ...without];
    if (next.length > maxSavedAccounts) {
      next.removeRange(maxSavedAccounts, next.length);
    }
    await _saveAll(next);
    return next;
  }

  Future<List<SavedAccount>> removeByUid(String uid) async {
    final next = (await load()).where((a) => a.uid != uid).toList();
    await _saveAll(next);
    return next;
  }

  Future<List<SavedAccount>> updateProfile({
    required String uid,
    String? displayName,
    String? iconUrl,
  }) async {
    final list = await load();
    var changed = false;
    final next = list.map((a) {
      if (a.uid != uid) return a;
      changed = true;
      return a.copyWith(
        displayName: displayName ?? a.displayName,
        iconUrl: iconUrl ?? a.iconUrl,
      );
    }).toList();
    if (changed) await _saveAll(next);
    return next;
  }
}
