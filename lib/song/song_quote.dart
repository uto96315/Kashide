class SongQuote {
  const SongQuote({
    required this.artist,
    required this.title,
    required this.lyrics,
    required this.listenUrl,
    this.artworkUrl,
  });

  final String artist;
  final String title;
  final String lyrics;
  final String listenUrl;
  final String? artworkUrl;
}
