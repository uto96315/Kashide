import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/screen_top.dart';

void main() {
  testWidgets('ScreenTop shows title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ScreenTop(title: '設定')),
      ),
    );
    expect(find.text('設定'), findsOneWidget);
  });

  testWidgets('AppBackButton pops route', (tester) async {
    var popped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Navigator(
            onPopPage: (route, result) {
              popped = true;
              return route.didPop(result);
            },
            pages: [
              MaterialPage(
                child: Builder(
                  builder: (context) => Scaffold(
                    body: AppBackButton(onPressed: () => Navigator.pop(context)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(popped, isTrue);
  });
}
