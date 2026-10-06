/// スワイプで見終わった（またはスキップした）投稿 ID を記録する。
void updateSwipeSeenIds({
  required Set<String> seenIds,
  required Iterable<String> postIds,
  required bool hasMorePosts,
  required String dismissedId,
}) {
  seenIds.add(dismissedId);
}
