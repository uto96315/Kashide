import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/timeline/timeline_filter.dart';

import 'helpers/fake_post.dart';

void main() {
  test('applyTimelineFilter by genre and comments', () {
    final a = fakePost(id: 'a', genres: const ['JPOP'], commentCount: 2, youtubeLink: 'https://youtu.be/a');
    final b = fakePost(id: 'b', genres: const ['ロック'], commentCount: 0, youtubeLink: '', explanation: '');
    final filtered = applyTimelineFilter(
      [a, b],
      const TimelineFilterState(
        genres: {'JPOP'},
        commentFilter: TimelineCommentFilter.withComments,
        youtubeFilter: TimelineTriFilter.yes,
      ),
    );
    expect(filtered.map((p) => p.id).toList(), ['a']);
  });
}
