import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/element/favorite/favorite_model.dart';
import 'package:str_gram_beta/providers.dart';

import '../helpers/fake_post.dart';

void main() {
  testWidgets('LyricPostCard shows lyrics and song meta', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteProvider.overrideWith((ref, args) {
            final model = FavoriteModel(args.postId, args.likedCount);
            model.isLiked = false;
            model.likedCount = args.likedCount ?? 0;
            return model;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricPostCard(
                post: fakePost(youtubeLink: ''),
                menuItems: const [PopupMenuItem(value: 'edit', child: Text('編集する'))],
                onMenu: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('砂漠の街に住んでても'), findsOneWidget);
    expect(find.text('365日'), findsOneWidget);
    expect(find.text('Mr.Children'), findsOneWidget);
    expect(find.text('#恋愛ソング'), findsOneWidget);
    expect(find.text('papy'), findsOneWidget);
  });

  testWidgets('LyricPostCard hide author on my page mode', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoriteProvider.overrideWith((ref, args) => FavoriteModel(args.postId, args.likedCount)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LyricPostCard(
                post: fakePost(),
                showAuthor: false,
                menuItems: const [],
                onMenu: (_) async {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('papy'), findsNothing);
    expect(find.text('約1時間前'), findsOneWidget);
  });
}
