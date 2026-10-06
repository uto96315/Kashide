import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/empty_state.dart';

void main() {
  testWidgets('EmptyState shows message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: EmptyState(message: 'まだ投稿がありません')),
      ),
    );
    expect(find.text('まだ投稿がありません'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });
}
