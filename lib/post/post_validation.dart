const postLyricsLimit = 300;
const postExplanationLimit = 300;

String? validatePostForm({
  required String singerName,
  required String singName,
  required String lyrics,
  required int explanationLength,
  int lyricsLimit = postLyricsLimit,
  int explanationLimit = postExplanationLimit,
}) {
  if (singerName.trim().isEmpty || singName.trim().isEmpty) {
    return '曲を一覧から選んでください';
  }
  final text = lyrics.trim();
  if (text.isEmpty) return '歌詞の範囲を選んでください';
  if (text.length > lyricsLimit) return '歌詞は$lyricsLimit文字以内で選んでください';
  if (explanationLength > explanationLimit) {
    return '思いは$explanationLimit文字以内にしてください';
  }
  return null;
}
