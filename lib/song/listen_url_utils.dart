/// 再生 URL が Apple Music / iTunes 曲ページかどうか（YouTube 等は除外）。
bool isAppleMusicListenUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final lower = url.toLowerCase();
  if (lower.contains('youtube.com') || lower.contains('youtu.be')) return false;
  return lower.contains('music.apple.com') || lower.contains('itunes.apple.com');
}
