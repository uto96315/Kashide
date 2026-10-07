import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/song/listen_url_resolver.dart';

/// カード表示向け: iTunes プレビュー（約30秒）をアプリ内再生。
class CardPreviewPlayer extends ChangeNotifier {
  CardPreviewPlayer(this._resolver);

  final ListenUrlResolver _resolver;
  final AudioPlayer _player = AudioPlayer();

  String? playingPostId;
  bool loading = false;

  bool get isPlaying => _player.playing;

  Future<void> playForPost(Post post) async {
    if (playingPostId == post.id && _player.playing) return;
    loading = true;
    notifyListeners();
    try {
      await _player.stop();
      playingPostId = null;
      final url = await _resolver.resolvePreviewForPost(post);
      if (url == null || url.isEmpty) return;
      await _player.setUrl(url);
      playingPostId = post.id;
      await _player.play();
    } catch (e, st) {
      debugPrint('Card preview play failed: $e\n$st');
      playingPostId = null;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    playingPostId = null;
    loading = false;
    notifyListeners();
  }

  Future<void> disposePlayer() async {
    await stop();
    await _player.dispose();
  }
}
