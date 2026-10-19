import 'package:flutter_test/flutter_test.dart';
import 'package:str_gram_beta/playlist/default_playlists.dart';

void main() {
  test('isSystemPlaylist recognizes built-in keys', () {
    expect(DefaultPlaylists.isSystemPlaylist(DefaultPlaylists.systemKeyFavorite), isTrue);
    expect(DefaultPlaylists.isSystemPlaylist(DefaultPlaylists.systemKeyMyPosts), isTrue);
    expect(DefaultPlaylists.isSystemPlaylist(null), isFalse);
    expect(DefaultPlaylists.isSystemPlaylist('custom'), isFalse);
  });
}
