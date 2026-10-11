import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:str_gram_beta/timeline/timeline_controls_tutorial.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows four highlighted tips and remembers completion', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final targets = List.generate(4, (_) => GlobalKey());
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (pageContext) {
            context = pageContext;
            return Scaffold(
              body: Row(
                children: [
                  for (final key in targets)
                    SizedBox(key: key, width: 44, height: 44),
                ],
              ),
            );
          },
        ),
      ),
    );

    final tutorial = TimelineControlsTutorial.showIfNeeded(
      context,
      uid: 'user-1',
      targets: targets,
    );
    await tester.pumpAndSettle();

    const titles = ['曲を自動で再生', '並び順を変える', '見たい投稿を探す', '表示を切り替える'];
    for (var index = 0; index < titles.length; index++) {
      final title = titles[index];
      expect(find.text(title), findsOneWidget);
      final cardTitle = tester.getRect(find.text(title));
      expect(cardTitle.top, greaterThanOrEqualTo(0));
      expect(
        cardTitle.bottom,
        lessThanOrEqualTo(
          tester.view.physicalSize.height / tester.view.devicePixelRatio,
        ),
      );
      await tester.tap(find.text(index == titles.length - 1 ? 'はじめる' : '次へ'));
      await tester.pumpAndSettle();
    }

    await tutorial;
    await TimelineControlsTutorial.showIfNeeded(
      context,
      uid: 'user-1',
      targets: targets,
    );
    await tester.pumpAndSettle();
    expect(find.text('曲を自動で再生'), findsNothing);
    semantics.dispose();
  });

  testWidgets('skip dismisses and remembers the tutorial', (tester) async {
    final targets = List.generate(4, (_) => GlobalKey());
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: Builder(
          builder: (pageContext) {
            context = pageContext;
            return Scaffold(
              body: Row(
                children: [
                  for (final key in targets)
                    SizedBox(key: key, width: 44, height: 44),
                ],
              ),
            );
          },
        ),
      ),
    );

    final tutorial = TimelineControlsTutorial.showIfNeeded(
      context,
      uid: 'user-2',
      targets: targets,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('スキップ'));
    await tester.pumpAndSettle();
    await tutorial;

    await TimelineControlsTutorial.showIfNeeded(
      context,
      uid: 'user-2',
      targets: targets,
    );
    await tester.pumpAndSettle();
    expect(find.text('曲を自動で再生'), findsNothing);
  });
}
