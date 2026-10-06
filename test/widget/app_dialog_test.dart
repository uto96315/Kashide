import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/app_dialog.dart';

void main() {
  testWidgets('showAppConfirm returns true when confirmed', (tester) async {
    late bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                result = await showAppConfirm(
                  context,
                  title: '削除',
                  message: '削除しますか？',
                  confirm: '削除する',
                  destructive: true,
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('削除しますか？'), findsOneWidget);
    await tester.tap(find.text('削除する'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('showAppMessage shows OK', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () => showAppMessage(context, '曲を選んでください'),
              child: const Text('open'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('曲を選んでください'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  });
}
