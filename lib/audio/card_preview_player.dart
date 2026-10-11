import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/song/listen_url_resolver.dart';

/// カード表示向け: iTunes プレビュー（約30秒）をアプリ内再生。
class CardPreviewPlayer extends ChangeNotifier {
  CardPreviewPlayer(this._resolver) {
    _playerStateSubscription = _player.playerStateStream.listen((_) {
      notifyListeners();
    });
  }

  final ListenUrlResolver _resolver;
  final AudioPlayer _player = AudioPlayer();
  late final StreamSubscription<PlayerState> _playerStateSubscription;
  int _requestId = 0;

  String? playingPostId;
  bool loading = false;

  bool get isPlaying => _player.playing;

  Future<void> playForPost(Post post) async {
    if (playingPostId == post.id && _player.playing) return;
    final requestId = ++_requestId;
    loading = true;
    notifyListeners();
    try {
      await _player.stop();
      playingPostId = null;
      final url = await _resolver.resolvePreviewForPost(post);
      if (requestId != _requestId) return;
      if (url == null || url.isEmpty) return;
      await _player.setUrl(url);
      if (requestId != _requestId) return;
      playingPostId = post.id;
      await _player.play();
    } catch (e, st) {
      debugPrint('Card preview play failed: $e\n$st');
      if (requestId == _requestId) playingPostId = null;
    } finally {
      if (requestId == _requestId) {
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    final requestId = ++_requestId;
    try {
      await _player.stop();
    } catch (_) {}
    if (requestId != _requestId) return;
    playingPostId = null;
    loading = false;
    notifyListeners();
  }

  Future<void> disposePlayer() async {
    await stop();
    await _playerStateSubscription.cancel();
    await _player.dispose();
  }
}
