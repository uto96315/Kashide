import 'package:in_app_review/in_app_review.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:str_gram_beta/common/default_genres.dart';
import 'package:str_gram_beta/domain/user_domain.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/post_domain.dart';
import 'swipe_seen_state.dart';
import 'timeline_filter.dart';
import 'package:timeago/timeago.dart' as timeAgo;

class TimelineModel extends ChangeNotifier {

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
  List blockedUsers = [];
  String? newPlaylistName;
  TimelineFilterState filter = TimelineFilterState.empty;
  List<String> masterGenreOptions = List<String>.from(kFallbackDefaultGenres);
  String? _serverGenreFilter;
  bool filterApplying = false;

  List<Post> get visiblePosts => applyTimelineFilter(postsList, filter);

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

  Future<void> setFilter(TimelineFilterState next) async {
    filter = next;
    if (!filter.isActive) {
      _serverGenreFilter = null;
      await getFirstPostData();
      return;
    }

    filterApplying = true;
    notifyListeners();
    try {
      if (canUseServerGenreQuery(filter)) {
        _serverGenreFilter = filter.genres.first;
        await _reloadPostsFromCurrentQuery();
      } else {
        _serverGenreFilter = null;
        await _expandLoadedPostsForFilter(maxPages: 5);
      }
    } finally {
      filterApplying = false;
      notifyListeners();
    }
  }

  String filterBannerText(int visibleCount) {
    if (!filter.isActive) return '';
    if (filterUsesServerGenre) {
      final g = _serverGenreFilter!;
      if (hasMorePosts) {
        return '$visibleCount件表示（「$g」を新着順 · まだ続きがある可能性があります）';
      }
      return '$visibleCount件表示（「$g」${postsList.length}件まで取得）';
    }
    if (hasMorePosts) {
      return '$visibleCount件表示 · 読み込み済み${postsList.length}件'
          '（未読み込みにも条件に合う投稿がある可能性があります。下へスクロールで追加読み込み）';
    }
    return '$visibleCount件表示 · 読み込み済み${postsList.length}件（ここまで全件）';
  }

  /// 初回・追加読み込みとも Firestore から **10件ずつ**。
  static const postsPageSize = 10;

  Future<void> _reloadPostsFromCurrentQuery() async {
    final snapshot = await _postsQuery.limit(postsPageSize).get();
    postsList = await _postsFromDocs(snapshot.docs);
    _lastDoc = snapshot.docs.isEmpty ? null : snapshot.docs.last;
    hasMorePosts = snapshot.docs.length == postsPageSize;
    postsReady = true;
  }

  Future<void> _expandLoadedPostsForFilter({required int maxPages}) async {
    var pages = 0;
    var lastVisible = -1;
    while (pages < maxPages && hasMorePosts) {
      final visible = applyTimelineFilter(postsList, filter).length;
      if (visible == lastVisible && visible >= 15) break;
      lastVisible = visible;
      await loadMorePosts();
      pages++;
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
          doc["youtubeLink"] ?? ""
      );
    }).toList();
    postsList.removeWhere((post) => blockedUsers.contains(post.posterId));
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  Query<Map<String, dynamic>> get _postsQuery {
    if (_serverGenreFilter != null) {
      return FirebaseFirestore.instance
          .collection('posts')
          .where('genres', arrayContains: _serverGenreFilter!)
          .orderBy('createdAt', descending: true);
    }
    return FirebaseFirestore.instance.collection('posts').orderBy('createdAt', descending: true);
  }

  Future<List<Post>> _postsFromDocs(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    if (docs.isEmpty) return [];
    final userInfo = await Future.wait(docs.map((doc) => getUserData(doc["posterId"])));
    final commentCount = await Future.wait(docs.map((doc) => getCommentCount(doc.id)));
    return docs.asMap().entries.map((entry) {
      final index = entry.key;
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
      );
    }).where((post) => !blockedUsers.contains(post.posterId)).toList();
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
    await getBlockedUsers();
    await loadLikedPostIds();
    if (filter.isActive && canUseServerGenreQuery(filter)) {
      _serverGenreFilter = filter.genres.first;
    } else {
      _serverGenreFilter = null;
    }
    await _reloadPostsFromCurrentQuery();
    if (filter.isActive && !canUseServerGenreQuery(filter)) {
      await _expandLoadedPostsForFilter(maxPages: 5);
    }
    debugPrint("投稿を読み込みました");
    notifyListeners();
  }

  Future<void> loadMorePosts() async {
    if (loadingMore || !hasMorePosts || _lastDoc == null) return;
    loadingMore = true;
    notifyListeners();
    try {
      final snapshot = await _postsQuery.startAfterDocument(_lastDoc!).limit(postsPageSize).get();
      final more = await _postsFromDocs(snapshot.docs);
      postsList.addAll(more);
      if (snapshot.docs.isNotEmpty) _lastDoc = snapshot.docs.last;
      hasMorePosts = snapshot.docs.length == postsPageSize;
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

  // ブロック処理
  Future blockUser(String posterId) async{
    final doc = FirebaseFirestore.instance.collection("users").doc(uid).collection("blockList");
    final targetUserDoc = FirebaseFirestore.instance.collection("users").doc(posterId);
    final blockedUserData = await targetUserDoc.get();

    await doc.add({
      "id": posterId,
      "blockedAt": DateTime.now(),
      "blockedUserName": blockedUserData["userName"],  // ここでブロックしたユーザーの名前
    });
    blockedUsers.add(posterId);
    postsList.removeWhere((post) => post.posterId == posterId);
    notifyListeners();
  }

  // ブロックされているユーザーの取得
  Future getBlockedUsers() async{
    final doc = FirebaseFirestore.instance.collection("users").doc(uid).collection("blockList");
    final snapshot = await doc.get();
    blockedUsers = snapshot.docs.asMap().entries.map((blockedUser){
      return blockedUser.value["id"];
    }).toList();
    print(blockedUsers);
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
}
