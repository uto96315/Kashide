import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/post_fab.dart';

void main() {
  testWidgets('PostFab invokes onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: PostFab(onPressed: () => tapped = true),
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.add), findsOneWidget);
    await tester.tap(find.byType(FloatingActionButton));
    expect(tapped, isTrue);
  });
}
