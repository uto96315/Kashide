import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_view_service.dart';

/// タイムライン一覧など、投稿が画面に載ったタイミングで閲覧数を加算する。
class RecordPostFeedView extends StatefulWidget {
  const RecordPostFeedView({
    super.key,
    required this.post,
    required this.child,
  });

  final Post post;
  final Widget child;

  @override
  State<RecordPostFeedView> createState() => _RecordPostFeedViewState();
}

class _RecordPostFeedViewState extends State<RecordPostFeedView> {
  static final _service = PostViewService();
  var _started = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _record());
  }

  Future<void> _record() async {
    if (_started) return;
    _started = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final updated = await _service.recordDetailView(
        postId: widget.post.id,
        viewerUid: uid,
      );
      if (!mounted) return;
      if (widget.post.viewCount != updated) {
        setState(() => widget.post.viewCount = updated);
      }
    } catch (e, st) {
      debugPrint('RecordPostFeedView failed: $e\n$st');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
