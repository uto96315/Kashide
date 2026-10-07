import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/post/post_view_service.dart';

void main() {
  test('viewCountFromFirestore defaults to 0', () {
    expect(viewCountFromFirestore({}), 0);
    expect(viewCountFromFirestore({'viewCount': 12}), 12);
  });

  test('max views per user is 5', () {
    expect(PostViewService.maxViewsPerUser, 5);
  });
}
