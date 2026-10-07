import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/timeline/timeline_sort.dart';

Post _post({required String id, required int likes, required int millis}) {
  return Post(
    'a',
    's',
    't',
    'u',
    likes,
    const [],
    'name',
    '',
    '',
    id,
    0,
    '',
    '',
    createdAtMillis: millis,
  );
}

void main() {
  test('applyTimelineSort mostLiked', () {
    final posts = [
      _post(id: '1', likes: 2, millis: 100),
      _post(id: '2', likes: 10, millis: 50),
      _post(id: '3', likes: 10, millis: 200),
    ];
    final sorted = applyTimelineSort(posts, TimelineSortOrder.mostLiked);
    expect(sorted.map((p) => p.id).toList(), ['3', '2', '1']);
  });

  test('applyTimelineSort newest', () {
    final posts = [
      _post(id: '1', likes: 0, millis: 100),
      _post(id: '2', likes: 0, millis: 300),
    ];
    final sorted = applyTimelineSort(posts, TimelineSortOrder.newest);
    expect(sorted.map((p) => p.id).toList(), ['2', '1']);
  });
}
