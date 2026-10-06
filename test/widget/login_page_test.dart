import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/login/login_page.dart';
import 'package:str_gram_beta/register/register_page.dart';

void main() {
  Future<void> pumpLogin(WidgetTester tester, {bool register = false}) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: register ? const RegisterPage() : const LoginPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('LoginPage shows login form by default', (tester) async {
    await pumpLogin(tester);
    expect(find.text('ログイン'), findsWidgets);
    expect(find.text('新規登録'), findsOneWidget);
  });

  testWidgets('RegisterPage starts on register tab', (tester) async {
    await pumpLogin(tester, register: true);
    expect(find.text('新規登録'), findsWidgets);
  });

  testWidgets('toggle switches to register form', (tester) async {
    await pumpLogin(tester);
    await tester.tap(find.text('新規登録').first);
    await tester.pumpAndSettle();
    expect(find.text('登録する'), findsOneWidget);
  });
}
