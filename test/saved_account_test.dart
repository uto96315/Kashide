import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/auth/saved_account.dart';

void main() {
  test('SavedAccount round-trip json', () {
    const account = SavedAccount(
      uid: 'u1',
      email: 'a@b.c',
      password: 'secret',
      displayName: 'ゆうと',
      iconUrl: 'https://example.com/icon.png',
    );
    final restored = SavedAccount.fromJson(account.toJson());
    expect(restored, isNotNull);
    expect(restored!.uid, account.uid);
    expect(restored.label, 'ゆうと');
  });

  test('label falls back to email', () {
    const account = SavedAccount(uid: 'u1', email: 'a@b.c', password: 'x');
    expect(account.label, 'a@b.c');
  });
}
