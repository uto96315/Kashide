import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/timeline/swipe_seen_state.dart';

void main() {
  group('updateSwipeSeenIds', () {
    test('tracks seen posts', () {
      final seen = <String>{};
      updateSwipeSeenIds(
        seenIds: seen,
        postIds: ['a', 'b'],
        hasMorePosts: true,
        dismissedId: 'a',
      );
      expect(seen, {'a'});
    });

    test('does not reset after all seen', () {
      final seen = <String>{};
      updateSwipeSeenIds(
        seenIds: seen,
        postIds: ['a'],
        hasMorePosts: false,
        dismissedId: 'a',
      );
      expect(seen, {'a'});
    });
  });
}
