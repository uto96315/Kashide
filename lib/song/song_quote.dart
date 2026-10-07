class SongQuote {
  const SongQuote({
    required this.artist,
    required this.title,
    required this.lyrics,
    required this.listenUrl,
    this.artworkUrl,
    this.lyricSegments = const [],
  });

  final String artist;
  final String title;
  final String lyrics;
  final String listenUrl;
  final String? artworkUrl;

  /// 2箇所以上のときのみ入る。空なら [lyrics] が1ブロック。
  final List<String> lyricSegments;
}
