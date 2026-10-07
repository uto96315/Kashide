import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'editPost/edit_post_model.dart';
import 'editUserDetails/edit_user_details_model.dart';
import 'element/favorite/favorite_model.dart';
import 'genre/genre_model.dart';
import 'home/home_model.dart';
import 'howToUse/how_to_use_model.dart';
import 'liked/liked_posts_model.dart';
import 'login/login_model.dart';
import 'mypage/my_model.dart';
import 'notification/notification_model.dart';
import 'playlist/playlist_model.dart';
import 'playlistDetails/playlist_details_model.dart';
import 'post/post_model.dart';
import 'postDetail/post_detail_model.dart';
import 'register/register_model.dart';
import 'registerUserDetails/register_user_details_model.dart';
import 'resetPassword/reset_password_model.dart';
import 'search/search_model.dart';
import 'searchResult/genreSearch/genre_search_model.dart';
import 'searchResult/lyricsSearch/lyrics_search_model.dart';
import 'searchResult/singSearch/sing_search_model.dart';
import 'searchResult/singerSearch/singer_result_model.dart';
import 'song/listen_url_resolver.dart';
import 'song/song_search_service.dart';
import 'analytics/app_analytics.dart';
import 'timeline/timeline_model.dart';
import 'user/block_list_model.dart';
import 'top/top_model.dart';

final appAnalyticsProvider = Provider<AppAnalytics>((ref) => AppAnalytics());

final songSearchServiceProvider = Provider<SongSearchService>((ref) {
  return SongSearchService();
});

final listenUrlResolverProvider = Provider<ListenUrlResolver>((ref) {
  return ListenUrlResolver(ref.watch(songSearchServiceProvider));
});

final homeProvider = ChangeNotifierProvider.autoDispose<HomeModel>((ref) {
  return HomeModel()..getLatestVersions();
});

/// ボトムタブ（0=ホーム）。詳細画面などからホームへ戻すときに使う。
class HomeTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void setTab(int index) => state = index;
}

final homeTabIndexProvider = NotifierProvider<HomeTabIndexNotifier, int>(HomeTabIndexNotifier.new);

final blockListProvider = ChangeNotifierProvider<BlockListModel>((ref) {
  return BlockListModel()..load();
});

final timelineProvider = ChangeNotifierProvider.autoDispose<TimelineModel>((ref) {
  final blockList = ref.watch(blockListProvider);
  final timeline = TimelineModel(blockList: blockList);
  ref.listen<BlockListModel>(blockListProvider, (_, next) {
    timeline.purgeBlockedPosts(next.blockedIds);
  });
  return timeline
    ..getFirstPostData()
    ..loadMasterGenres()
    ..getPlayListData();
});

final searchProvider = ChangeNotifierProvider.autoDispose<SearchModel>((ref) {
  return SearchModel()
    ..getUserData()
    ..getDefaultGenres();
});

final playlistProvider = ChangeNotifierProvider.autoDispose<PlaylistModel>((ref) {
  return PlaylistModel()..getPlaylists();
});

final myPageProvider = ChangeNotifierProvider.autoDispose<MyModel>((ref) {
  return MyModel()
    ..getUserData()
    ..getUserPosts()
    ..loadLikedCount()
    ..getVersions();
});

final loginProvider = ChangeNotifierProvider.autoDispose<LoginModel>((ref) {
  return LoginModel();
});

final registerProvider = ChangeNotifierProvider.autoDispose<RegisterModel>((ref) {
  return RegisterModel();
});

final registerUserDetailsProvider =
    ChangeNotifierProvider.autoDispose<RegisterUserDetailsModel>((ref) {
  return RegisterUserDetailsModel();
});

final resetPasswordProvider =
    ChangeNotifierProvider.autoDispose<ResetPasswordModel>((ref) {
  return ResetPasswordModel();
});

final topProvider = ChangeNotifierProvider.autoDispose<TopModel>((ref) {
  return TopModel();
});

final notificationProvider =
    ChangeNotifierProvider.autoDispose<NotificationModel>((ref) {
  return NotificationModel()..getToken();
});

final howToUseProvider = ChangeNotifierProvider.autoDispose<HowToUseModel>((ref) {
  return HowToUseModel()..getQuestions();
});

final postProvider =
    ChangeNotifierProvider.autoDispose.family<PostModel, String?>((ref, defaultGenre) {
  return PostModel(defaultGenre)
    ..setDefaultGenre(defaultGenre)
    ..getDefaultGenres();
});

typedef GenreArgs = ({String genre, String condition});

final genreProvider =
    ChangeNotifierProvider.autoDispose.family<GenreModel, GenreArgs>((ref, args) {
  return GenreModel(args.genre, args.condition)
    ..getGenrePosts(args.genre)
    ..getPlayListData()
    ..loadPosterProfile(args.genre);
});

final lyricsSearchProvider =
    ChangeNotifierProvider.autoDispose.family<LyricsSearchModel, String>((ref, word) {
  return LyricsSearchModel(word)..searchFromLyrics(word);
});

final singSearchProvider =
    ChangeNotifierProvider.autoDispose.family<SingSearchModel, String>((ref, word) {
  return SingSearchModel(word)..searchFromSing(word);
});

final singerSearchProvider =
    ChangeNotifierProvider.autoDispose.family<SingerSearchModel, String>((ref, word) {
  return SingerSearchModel(word)..searchFromSinger(word);
});

final genreSearchProvider =
    ChangeNotifierProvider.autoDispose.family<GenreSearchModel, String>((ref, word) {
  return GenreSearchModel(word)..searchFromGenre(word);
});

final playlistDetailsProvider = ChangeNotifierProvider.autoDispose
    .family<PlaylistDetailsModel, String>((ref, playlistId) {
  return PlaylistDetailsModel(playlistId)..getPlaylistDetail();
});

/// 同じ投稿のいいねボタンは件数の初期値が変わっても同じ状態を共有する。
class FavoriteArgs {
  FavoriteArgs(this.postId, this.likedCount);

  final String postId;
  final int? likedCount;

  @override
  bool operator ==(Object other) =>
      other is FavoriteArgs && other.postId == postId;

  @override
  int get hashCode => postId.hashCode;
}

final favoriteProvider = ChangeNotifierProvider.autoDispose
    .family<FavoriteModel, FavoriteArgs>((ref, args) {
  return FavoriteModel(args.postId, args.likedCount)..checkLiked();
});

final likedPostsProvider = ChangeNotifierProvider.autoDispose<LikedPostsModel>((ref) {
  return LikedPostsModel()..load();
});

final postDetailProvider =
    ChangeNotifierProvider.autoDispose.family<PostDetailModel, String>((ref, id) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  final model = PostDetailModel(id, false)..getPost(id)..getComments(id);
  if (uid != null) {
    model.getUserData(uid);
  }
  return model;
});

class EditPostArgs {
  EditPostArgs({
    required this.postId,
    required this.defaultText,
    required this.defaultSingerName,
    required this.defaultSingName,
    required this.defaultGenreList,
    required this.explanation,
    required this.youtubeLink,
  });

  final String postId;
  final String defaultText;
  final String defaultSingerName;
  final String defaultSingName;
  final List defaultGenreList;
  final String explanation;
  final String youtubeLink;

  @override
  bool operator ==(Object other) {
    return other is EditPostArgs &&
        other.postId == postId &&
        other.defaultText == defaultText &&
        other.defaultSingerName == defaultSingerName &&
        other.defaultSingName == defaultSingName &&
        other.explanation == explanation &&
        other.youtubeLink == youtubeLink &&
        listEquals(other.defaultGenreList, defaultGenreList);
  }

  @override
  int get hashCode => Object.hash(
        postId,
        defaultText,
        defaultSingerName,
        defaultSingName,
        explanation,
        youtubeLink,
        Object.hashAll(defaultGenreList),
      );
}

final editPostProvider = ChangeNotifierProvider.autoDispose
    .family<EditPostModel, EditPostArgs>((ref, args) {
  return EditPostModel(
    args.defaultText,
    args.defaultSingerName,
    args.defaultSingName,
    args.defaultGenreList,
    args.postId,
    args.explanation,
    args.youtubeLink,
  )..getDefaultGenres();
});

class EditUserArgs {
  EditUserArgs({
    required this.userName,
    required this.userIntroduction,
    required this.userGender,
    required this.userAge,
    required this.userFavorite,
    required this.userImageUrl,
  });

  final String userName;
  final String userIntroduction;
  final String userGender;
  final String userAge;
  final List<dynamic> userFavorite;
  final String userImageUrl;

  @override
  bool operator ==(Object other) {
    return other is EditUserArgs &&
        other.userName == userName &&
        other.userIntroduction == userIntroduction &&
        other.userGender == userGender &&
        other.userAge == userAge &&
        other.userImageUrl == userImageUrl &&
        listEquals(other.userFavorite, userFavorite);
  }

  @override
  int get hashCode => Object.hash(
        userName,
        userIntroduction,
        userGender,
        userAge,
        userImageUrl,
        Object.hashAll(userFavorite),
      );
}

final editUserDetailsProvider = ChangeNotifierProvider.autoDispose
    .family<EditUserDetailsModel, EditUserArgs>((ref, args) {
  return EditUserDetailsModel(
    args.userName,
    args.userIntroduction,
    args.userGender,
    args.userAge,
    args.userFavorite,
    args.userImageUrl,
  );
});
