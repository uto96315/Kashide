import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/primary_button.dart';

void main() {
  testWidgets('PrimaryButton fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: '投稿する', onPressed: () => tapped = true),
        ),
      ),
    );
    await tester.tap(find.text('投稿する'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('PrimaryButton disabled when onPressed is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PrimaryButton(label: '投稿する', onPressed: null),
        ),
      ),
    );
    await tester.tap(find.text('投稿する'));
    await tester.pump();
    // No exception; button should not respond (gesture absorbed by disabled state)
  });
}
