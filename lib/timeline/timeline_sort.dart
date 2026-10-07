import 'package:str_gram_beta/domain/post_domain.dart';

enum TimelineSortOrder {
  newest,
  mostLiked,
}

extension TimelineSortOrderLabel on TimelineSortOrder {
  String get label {
    switch (this) {
      case TimelineSortOrder.newest:
        return '新着順';
      case TimelineSortOrder.mostLiked:
        return 'いいね数順';
    }
  }
}

List<Post> applyTimelineSort(List<Post> posts, TimelineSortOrder order) {
  if (posts.length <= 1) return posts;
  final sorted = posts.toList();
  switch (order) {
    case TimelineSortOrder.newest:
      sorted.sort((a, b) => b.createdAtMillis.compareTo(a.createdAtMillis));
    case TimelineSortOrder.mostLiked:
      sorted.sort((a, b) {
        final byLikes = b.likedCount.compareTo(a.likedCount);
        if (byLikes != 0) return byLikes;
        return b.createdAtMillis.compareTo(a.createdAtMillis);
      });
  }
  return sorted;
}
