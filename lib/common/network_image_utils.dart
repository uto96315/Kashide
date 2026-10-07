/// Firestore 等で `""` や `"null"` 文字列が入ることがあるため、NetworkImage 前に判定する。
bool isUsableNetworkImageUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  return trimmed.isNotEmpty && trimmed != 'null';
}

String? normalizeNetworkImageUrl(String? url) {
  if (!isUsableNetworkImageUrl(url)) return null;
  return url!.trim();
}
