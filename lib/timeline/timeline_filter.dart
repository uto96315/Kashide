import 'package:str_gram_beta/domain/post_domain.dart';

enum TimelineCommentFilter {
  all,
  withComments,
  withoutComments,
}

enum TimelineTriFilter {
  all,
  yes,
  no,
}

class TimelineFilterState {
  const TimelineFilterState({
    this.genres = const {},
    this.commentFilter = TimelineCommentFilter.all,
    this.youtubeFilter = TimelineTriFilter.all,
    this.explanationFilter = TimelineTriFilter.all,
  });

  final Set<String> genres;
  final TimelineCommentFilter commentFilter;
  final TimelineTriFilter youtubeFilter;
  final TimelineTriFilter explanationFilter;

  bool get isActive =>
      genres.isNotEmpty ||
      commentFilter != TimelineCommentFilter.all ||
      youtubeFilter != TimelineTriFilter.all ||
      explanationFilter != TimelineTriFilter.all;

  TimelineFilterState copyWith({
    Set<String>? genres,
    TimelineCommentFilter? commentFilter,
    TimelineTriFilter? youtubeFilter,
    TimelineTriFilter? explanationFilter,
  }) {
    return TimelineFilterState(
      genres: genres ?? this.genres,
      commentFilter: commentFilter ?? this.commentFilter,
      youtubeFilter: youtubeFilter ?? this.youtubeFilter,
      explanationFilter: explanationFilter ?? this.explanationFilter,
    );
  }

  static const empty = TimelineFilterState();
}

List<Post> applyTimelineFilter(List<Post> posts, TimelineFilterState filter) {
  return posts.where((post) {
    if (filter.genres.isNotEmpty) {
      final postGenres = post.genres.whereType<String>().where((g) => g.isNotEmpty).toSet();
      if (!filter.genres.any(postGenres.contains)) return false;
    }
    switch (filter.commentFilter) {
      case TimelineCommentFilter.all:
        break;
      case TimelineCommentFilter.withComments:
        if (post.commentCount <= 0) return false;
      case TimelineCommentFilter.withoutComments:
        if (post.commentCount > 0) return false;
    }
    switch (filter.youtubeFilter) {
      case TimelineTriFilter.all:
        break;
      case TimelineTriFilter.yes:
        if (post.youtubeLink.isEmpty) return false;
      case TimelineTriFilter.no:
        if (post.youtubeLink.isNotEmpty) return false;
    }
    switch (filter.explanationFilter) {
      case TimelineTriFilter.all:
        break;
      case TimelineTriFilter.yes:
        if (post.explanation.trim().isEmpty) return false;
      case TimelineTriFilter.no:
        if (post.explanation.trim().isNotEmpty) return false;
    }
    return true;
  }).toList(growable: false);
}

Set<String> genresInPosts(List<Post> posts) {
  final genres = <String>{};
  for (final post in posts) {
    for (final genre in post.genres.whereType<String>()) {
      if (genre.isNotEmpty) genres.add(genre);
    }
  }
  final sorted = genres.toList()..sort();
  return sorted.toSet();
}
