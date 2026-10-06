import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/common/playlist_picker_sheet.dart';

void main() {
  testWidgets('playlist picker lists playlists and creates new', (tester) async {
    String? selectedId;
    String? createdName;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showPlaylistPickerSheet(
                  context,
                  playlists: [
                    {'id': 'pl-1', 'playlistName': 'お気に入り'},
                  ],
                  onSelect: (id) async {
                    selectedId = id;
                  },
                  onCreate: (name) async {
                    createdName = name;
                  },
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

    expect(find.text('プレイリストに追加'), findsOneWidget);
    expect(find.text('お気に入り'), findsOneWidget);

    await tester.tap(find.text('お気に入り'));
    await tester.pumpAndSettle();
    expect(selectedId, 'pl-1');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('新しいプレイリストを作る'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '夜用');
    await tester.tap(find.text('作る'));
    await tester.pumpAndSettle();

    expect(createdName, '夜用');
  });
}
