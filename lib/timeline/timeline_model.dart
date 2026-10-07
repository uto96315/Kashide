import 'package:in_app_review/in_app_review.dart';
import 'package:str_gram_beta/post/post_lyrics.dart';
import 'package:str_gram_beta/post/post_view_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/common/default_genres.dart';
import 'package:str_gram_beta/domain/user_domain.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/post_domain.dart';
import '../post/post_validation.dart';
import '../user/block_list_model.dart';
import 'swipe_seen_state.dart';
import 'timeline_filter.dart';
import 'timeline_sort.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class TimelineModel extends ChangeNotifier {
  TimelineModel({required this.blockList});

  final BlockListModel blockList;
  bool _disposed = false;
  final addPlaylistController = TextEditingController();

  var user = FirebaseAuth.instance.currentUser;
  var uid = FirebaseAuth.instance.currentUser?.uid;
  bool postsReady = false;
  List<Post> postsList = [];
  final seenSwipeIds = <String>{};
  final likedPostIds = <String>{};
  DocumentSnapshot? _lastDoc;
  bool hasMorePosts = true;
  bool loadingMore = false;
  List playList = [];
  String? newPlaylistName;
  TimelineFilterState filter = TimelineFilterState.empty;
  TimelineSortOrder sortOrder = TimelineSortOrder.newest;
  List<String> masterGenreOptions = List<String>.from(kFallbackDefaultGenres);
  String? _serverGenreFilter;
  /// Firestore 複合インデックス未作成時はサーバー側ジャンル絞り込みを使わない。
  bool _serverGenreQueryDisabled = false;
  /// 複合インデックスが無いときは `createdAt` の第2ソートを外して再試行する。
  bool _likedSortSkipCreatedAtTiebreak = false;
  String? sortLoadError;
  String? filterLoadError;
  /// ジャンル1件絞り込みを Firestore ではなく端末側で行っている。
  bool filterClientGenreFallback = false;
  bool filterApplying = false;
  bool filterPrefetching = false;
  bool _filterBackgroundCancelled = false;

  List<Post> get visiblePosts {
    final eligible = postsList
        .where((p) => shouldShowPostInFeed(p, uid, blockedPosterIds: blockList.blockedIds))
        .toList();
    var result = applyTimelineFilter(eligible, filter);
    if (!_usesServerSortOrder) {
      result = applyTimelineSort(result, sortOrder);
    }
    return result;
  }

  /// 絞り込み結果を端末側でいいね数ソートする必要がある（複合条件など）。
  bool get _needsClientMostLikedSort =>
      sortOrder == TimelineSortOrder.mostLiked && filter.isActive && !filterUsesServerGenre;

  /// Firestore の取得順がそのまま表示順になるか（クライアント側ソート不要か）。
  bool get _usesServerSortOrder {
    if (_needsClientMostLikedSort) return false;
    return true;
  }

  bool get filterUsesServerGenre => _serverGenreFilter != null;

  /// 絞り込み UI 用（マスタ＋投稿にだけあるタグ）。
  Set<String> get availableFilterGenres {
    final set = masterGenreOptions.toSet();
    set.addAll(genresInPosts(postsList));
    return set;
  }

  Future<void> loadMasterGenres() async {
    masterGenreOptions = await fetchDefaultGenres();
    notifyListeners();
  }

  static bool canUseServerGenreQuery(TimelineFilterState f) {
    return f.genres.length == 1 &&
        f.commentFilter == TimelineCommentFilter.all &&
        f.youtubeFilter == TimelineTriFilter.all &&
        f.explanationFilter == TimelineTriFilter.all;
  }

  Future<void> setSortOrder(TimelineSortOrder next) async {
    if (sortOrder == next) return;
    sortOrder = next;
    _likedSortSkipCreatedAtTiebreak = false;
    sortLoadError = null;
    _filterBackgroundCancelled = true;
    filterPrefetching = false;
    notifyListeners();
    await getFirstPostData();
  }

  Future<void> setFilter(TimelineFilterState next) async {
    filter = next;
    _filterBackgroundCancelled = true;
    filterLoadError = null;
    filterClientGenreFallback = false;
    if (!filter.isActive) {
      _serverGenreFilter = null;
      filterPrefetching = false;
      await getFirstPostData();
      return;
    }

    filterApplying = true;
    _filterBackgroundCancelled = false;
    notifyListeners();
    try {
      await _reloadFilteredFeed();
      _startFilteredBackgroundPrefetch();
    } on FirebaseException catch (e, st) {
      debugPrint('Timeline setFilter failed: ${e.code} ${e.message}\n$st');
      filterLoadError = _feedLoadErrorMessage(
        e,
        forFilter: true,
        forLikedSort: sortOrder == TimelineSortOrder.mostLiked,
      );
      postsList = [];
      postsReady = true;
      hasMorePosts = false;
      filterPrefetching = false;
    } finally {
      filterApplying = false;
      notifyListeners();
    }
  }

  Future<void> _reloadFilteredFeed() async {
    filterLoadError = null;
    _syncServerGenreFilter();
    await _reloadPostsFromCurrentQuery();
    await _loadFilteredUntilVisible(filterInitialVisibleTarget, maxBatches: filterMaxScanBatches);
  }

  String _feedLoadErrorMessage(
    FirebaseException e, {
    required bool forFilter,
    required bool forLikedSort,
  }) {
    if (e.code == 'failed-precondition') {
      if (forFilter && forLikedSort) {
        return '絞り込みと並び替え用の Firestore インデックスを準備中です。'
            'コンソールでインデックスが「有効」になるまで待つか、条件を変えてお試しください。';
      }
      if (forFilter) {
        return '絞り込み用の Firestore インデックスを準備中です。'
            'しばらく待つか、条件を変えてお試しください。';
      }
      return 'Firestore インデックスを準備中です。構築完了後にもう一度お試しください。';
    }
    if (forFilter) {
      return '絞り込み結果を読み込めませんでした。通信環境を確認して再度お試しください。';
    }
    return '投稿を読み込めませんでした。通信環境を確認して再度お試しください。';
  }

  void _syncServerGenreFilter() {
    if (_serverGenreQueryDisabled) {
      _serverGenreFilter = null;
      return;
    }
    _serverGenreFilter = canUseServerGenreQuery(filter) ? filter.genres.first : null;
  }

  String filterBannerText(int visibleCount) {
    if (!filter.isActive) return '';
    final fallbackNote = filterClientGenreFallback ? '端末側ジャンル絞り込み · ' : '';
    final suffix = filterPrefetching
        ? ' · 続きを読み込み中…'
        : hasMorePosts
            ? ' · 下へスクロールでさらに表示'
            : ' · ここまで全件';
    final sortLabel = sortOrder.label;
    if (filterUsesServerGenre) {
      final g = _serverGenreFilter!;
      return '$fallbackNote$visibleCount件（ジャンル「$g」· $sortLabel）$suffix';
    }
    if (_needsClientMostLikedSort) {
      return '$fallbackNote$visibleCount件 · $sortLabel（直近${postsList.length}件から集計）$suffix';
    }
    return '$fallbackNote$visibleCount件 · $sortLabel$suffix';
  }

  /// 通常タイムラインの1ページあたり件数。
  static const postsPageSize = 10;

  /// 絞り込み時: まず条件に合う投稿をこの件数まで揃えてから表示。
  static const filterInitialVisibleTarget = 30;

  /// 絞り込み時の Firestore 1リクエストあたり件数。
  static const filterFetchBatchSize = 40;

  /// 絞り込み初期スキャンの上限（40×15=600投稿まで走査）。
  static const filterMaxScanBatches = 15;

  int get _currentFetchSize {
    if (filter.isActive) return filterFetchBatchSize;
    if (sortOrder == TimelineSortOrder.mostLiked) return filterInitialVisibleTarget;
    return postsPageSize;
  }

  Future<void> _reloadPostsFromCurrentQuery() async {
    final snapshot = await _queryPostsPage(limit: _currentFetchSize);
    postsList = await _postsFromDocs(snapshot.docs);
    _lastDoc = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    hasMorePosts = snapshot.docs.length == _currentFetchSize;
    postsReady = true;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _queryPostsPage({
    DocumentSnapshot? startAfter,
    required int limit,
  }) async {
    Future<QuerySnapshot<Map<String, dynamic>>> run() {
      Query<Map<String, dynamic>> q = _postsQuery;
      if (startAfter != null) {
        q = q.startAfterDocument(startAfter);
      }
      return q.limit(limit).get();
    }

    try {
      return await run();
    } on FirebaseException catch (e) {
      if (e.code != 'failed-precondition') rethrow;
      if (_serverGenreFilter != null && !_serverGenreQueryDisabled) {
        debugPrint(
          'Firestore index missing for genre filter; using client-side genre filter. '
          'Deploy firestore.indexes.json or use the link in the error.',
        );
        _serverGenreQueryDisabled = true;
        _serverGenreFilter = null;
        if (filter.isActive && canUseServerGenreQuery(filter)) {
          filterClientGenreFallback = true;
        }
        return run();
      }
      if (sortOrder == TimelineSortOrder.mostLiked && !_likedSortSkipCreatedAtTiebreak) {
        debugPrint('Retrying likedCount sort without createdAt tiebreak index.');
        _likedSortSkipCreatedAtTiebreak = true;
        return run();
      }
      rethrow;
    }
  }

  Future<void> _loadFilteredUntilVisible(int minVisible, {required int maxBatches}) async {
    var batches = 0;
    while (batches < maxBatches && hasMorePosts) {
      if (!_needsClientMostLikedSort && visiblePosts.length >= minVisible) break;
      final loaded = await _fetchNextPostsPage();
      if (!loaded) break;
      batches++;
      notifyListeners();
    }
  }

  void _startFilteredBackgroundPrefetch() {
    if (!filter.isActive) return;
    _filterBackgroundCancelled = false;
    Future<void>(() async {
      filterPrefetching = true;
      notifyListeners();
      try {
        var batches = 0;
        while (!_filterBackgroundCancelled &&
            batches < 8 &&
            hasMorePosts &&
            visiblePosts.length < filterInitialVisibleTarget * 2) {
          final loaded = await _fetchNextPostsPage();
          if (!loaded) break;
          batches++;
          notifyListeners();
        }
      } finally {
        if (!_filterBackgroundCancelled) {
          filterPrefetching = false;
          notifyListeners();
        }
      }
    });
  }

  /// 次ページ取得。失敗時は [hasMorePosts] を false にして false を返す。
  Future<bool> _fetchNextPostsPage() async {
    if (!hasMorePosts || _lastDoc == null) return false;
    try {
      final snapshot = await _queryPostsPage(startAfter: _lastDoc, limit: _currentFetchSize);
      final more = await _postsFromDocs(snapshot.docs);
      postsList.addAll(more);
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      hasMorePosts = snapshot.docs.length == _currentFetchSize;
      return true;
    } on FirebaseException catch (e, st) {
      debugPrint('Timeline loadMore failed: ${e.code} ${e.message}\n$st');
      hasMorePosts = false;
      return false;
    }
  }

  // ユーザー情報を取得する関数
  Future getUserData(String uid) async {
    final doc = FirebaseFirestore.instance.collection("users").doc(uid);
    final snapshot = await doc.get();
    final data = snapshot.data();
    final userName = data?["userName"];
    final userImageUrl = data?["iconUrl"];
    return [userName, userImageUrl];
  }

  // プレイリストを取得する関数
  Future getPlayListData()async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid).collection("playlists");
    final snapshot = await doc.get();
    playList = snapshot.docs.asMap().entries.map((entry){
      return {
        "id": entry.value.id,
        "playlistName": entry.value["playlistName"],
      };
    }).toList();
    notifyListeners();
  }

  // 投稿を取得する処理
  Future getPosts() async {
    final doc = FirebaseFirestore.instance
        .collection("posts")
        // .where("posterId", whereNotIn: blockedUsers)
        .orderBy("createdAt", descending: true);
    final snapshot = await doc.get();

    final userInfo = await Future.wait(
        snapshot.docs.map((doc) => getUserData(doc["posterId"])).toList());

    final commentCount = await Future.wait(
      snapshot.docs.map((doc) => getCommentCount(doc.id)).toList()
    );


    postsList = snapshot.docs.asMap().entries.map((entry) {
      int index = entry.key;
      final doc = entry.value;

      return Post(
          doc["artist"],
          doc["singName"],
          doc["text"],
          doc["posterId"],
          doc["likedCount"],
          doc["genres"],
          "${userInfo[index][0]}",
          "${userInfo[index][1]}",
          createTimeMessage(doc["createdAt"].toDate()),
          doc.id,
          commentCount[index],
          doc["explanation"] ?? "",
          doc["youtubeLink"] ?? "",
          viewCount: viewCountFromFirestore(doc.data()),
          textSegments: lyricSegmentsFromFirestore(doc.data()),
      );
    }).toList();
    postsList.removeWhere((post) => blockList.isBlocked(post.posterId));
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  Query<Map<String, dynamic>> get _postsQuery {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection('posts');

    if (_serverGenreFilter != null) {
      query = query.where('genres', arrayContains: _serverGenreFilter!);
    }

    if (sortOrder == TimelineSortOrder.mostLiked) {
      query = query.orderBy('likedCount', descending: true);
      if (!_likedSortSkipCreatedAtTiebreak) {
        query = query.orderBy('createdAt', descending: true);
      }
      return query;
    }
    return query.orderBy('createdAt', descending: true);
  }

  Future<List<Post>> _postsFromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return [];
    final userInfo = await Future.wait(docs.map((doc) => getUserData(doc["posterId"])));
    final commentCount = await Future.wait(docs.map((doc) => getCommentCount(doc.id)));
    return docs.asMap().entries.map((entry) {
      final index = entry.key;
      final doc = entry.value;
      final created = doc["createdAt"].toDate();
      return Post(
        doc["artist"],
        doc["singName"],
        doc["text"],
        doc["posterId"],
        (doc["likedCount"] as num?)?.toInt() ?? 0,
        doc["genres"],
        "${userInfo[index][0]}",
        "${userInfo[index][1]}",
        createTimeMessage(created),
        doc.id,
        commentCount[index],
        doc["explanation"] ?? "",
        doc["youtubeLink"] ?? "",
        createdAtMillis: created.millisecondsSinceEpoch,
        viewCount: viewCountFromFirestore(doc.data()),
        textSegments: lyricSegmentsFromFirestore(doc.data()),
      );
    }).where((post) => !blockList.isBlocked(post.posterId)).toList();
  }

  void removePostsByPoster(String posterId) {
    postsList.removeWhere((post) => post.posterId == posterId);
    notifyListeners();
  }

  void purgeBlockedPosts(Set<String> blockedIds) {
    if (blockedIds.isEmpty) return;
    postsList.removeWhere((post) => blockedIds.contains(post.posterId));
    notifyListeners();
  }

  // 最初に１０件を取得する
  Future<void> loadLikedPostIds() async {
    if (uid == null) return;
    final snapshot = await FirebaseFirestore.instance.collection("users").doc(uid).collection("likePost").get();
    likedPostIds
      ..clear()
      ..addAll(snapshot.docs.map((doc) => doc.id));
    seenSwipeIds.addAll(likedPostIds);
    notifyListeners();
  }

  bool isVisibleInSwipeDeck(Post post) {
    if (blockList.isBlocked(post.posterId)) return false;
    return !seenSwipeIds.contains(post.id) && !likedPostIds.contains(post.id);
  }

  void markSwipeSeen(String id) {
    updateSwipeSeenIds(
      seenIds: seenSwipeIds,
      postIds: postsList.map((post) => post.id),
      hasMorePosts: hasMorePosts,
      dismissedId: id,
    );
    notifyListeners();
  }

  Future getFirstPostData() async {
    await loadLikedPostIds();
    _filterBackgroundCancelled = true;
    filterPrefetching = false;
    sortLoadError = null;
    filterLoadError = null;
    filterClientGenreFallback = false;
    if (filter.isActive) {
      try {
        await _reloadFilteredFeed();
        _startFilteredBackgroundPrefetch();
      } on FirebaseException catch (e, st) {
        debugPrint('Timeline initial load failed: ${e.code} ${e.message}\n$st');
        final message = _feedLoadErrorMessage(
          e,
          forFilter: true,
          forLikedSort: sortOrder == TimelineSortOrder.mostLiked,
        );
        if (sortOrder == TimelineSortOrder.mostLiked) sortLoadError = message;
        filterLoadError = message;
        postsList = [];
        postsReady = true;
        hasMorePosts = false;
        notifyListeners();
        return;
      }
    } else {
      _serverGenreFilter = null;
      try {
        await _reloadPostsFromCurrentQuery();
      } on FirebaseException catch (e, st) {
        debugPrint('Timeline initial load failed: ${e.code} ${e.message}\n$st');
        if (sortOrder == TimelineSortOrder.mostLiked) {
          sortLoadError = _feedLoadErrorMessage(e, forFilter: false, forLikedSort: true);
        }
        postsList = [];
        postsReady = true;
        hasMorePosts = false;
        notifyListeners();
        return;
      }
    }
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  Future<void> loadMorePosts() async {
    if (loadingMore || !hasMorePosts || _lastDoc == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      await _fetchNextPostsPage();
    } on FirebaseException {
      // _fetchNextPostsPage 内で hasMorePosts を更新済み
    } finally {
      loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> likePost(String id) async {
    if (uid == null) return;
    final whoDoc = FirebaseFirestore.instance
        .collection("posts")
        .doc(id)
        .collection("likedUsers")
        .doc(uid);
    if ((await whoDoc.get()).exists) {
      likedPostIds.add(id);
      seenSwipeIds.add(id);
      notifyListeners();
      return;
    }
    final likedNumber = (await FirebaseFirestore.instance
            .collection("posts")
            .doc(id)
            .collection("likedUsers")
            .get())
        .docs
        .length;
    final nextCount = likedNumber + 1;
    await Future.wait([
      FirebaseFirestore.instance.collection("users").doc(uid).collection("likePost").doc(id).set({
        "postId": id,
        "likedAt": DateTime.now(),
      }),
      FirebaseFirestore.instance.collection("posts").doc(id).update({"likedCount": nextCount}),
      whoDoc.set({"likedAt": DateTime.now(), "likedUser": uid}),
    ]);
    for (final post in postsList) {
      if (post.id == id) {
        post.likedCount = nextCount;
        break;
      }
    }
    likedPostIds.add(id);
    seenSwipeIds.add(id);
    notifyListeners();
  }

  // 投稿時間から〜分前に変換する
  String createTimeMessage(DateTime postDateTime) {
    final now = DateTime.now();
    final difference = now.difference(postDateTime);
    return timeAgo.format(now.subtract(difference), locale: "ja");
  }


  // コメント数の取得
  Future getCommentCount(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id).collection("comments");
     final snapshot = await doc.get();
     final count = snapshot.docs.length;

     return count;
  }

  // 投稿を削除する処理
  // todo: 処理後にダイアログを表示する
  Future deletePosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("posts").doc(id);

    postsList.removeWhere((post) => post.id == id);

    await doc.delete();
    notifyListeners();
  }

  // 投稿を報告する処理
  // todo: 処理後にダイアログを表示する
  Future reportPosts(String id) async{
    final doc = FirebaseFirestore.instance
        .collection("reportedPosts");

    await doc.add({
      "id": id,
      "reportedAt": DateTime.now(),
      "posterId": uid
    });
    notifyListeners();
  }

  // Youtubeアプリを開く処理
  Future launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print(e.toString());
    }
  }

  // プレイリストに追加する処理
  Future addToPlaylist(String playlistId, String artist, String songName, String youtubeLink, String postId)async{
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid).collection("playlists")
        .doc(playlistId).collection("songs");

    try {
      await doc.add({
        "singName": songName,
        "artist": artist,
        "youtubeUrl": youtubeLink,
        "postId": postId,
        "addAt": DateTime.now(),
      });
      print("プレイリストに追加しました");
    } catch(e) {
      print(e.toString());
    }
    notifyListeners();
  }

  // 新しいプレイリストの文字列
  void setNewName( String text) {
    newPlaylistName = text;
    notifyListeners();
  }

  // プレイリストを追加する
  Future addNewPlaylist()async{
    newPlaylistName = addPlaylistController.text;
    final doc = FirebaseFirestore.instance
        .collection("users").doc(uid)
        .collection("playlists");
    await doc.add({
      "createdAt": DateTime.now(),
      "playlistName": newPlaylistName,
    });
    await getPlayListData();
    notifyListeners();
  }

  // レビューを促す処理
  void requestReview() {
    final review = InAppReview.instance;
    review.isAvailable().then((available) {
      if (available) {
        review.requestReview();
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    addPlaylistController.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }
}
