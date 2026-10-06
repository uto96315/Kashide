import 'package:str_gram_beta/domain/post_domain.dart';

const postLyricsLimit = 300;
const postExplanationLimit = 300;
/// 歌詞がこれ未満の他人投稿はタイムライン等に出さない（自分の投稿は常に表示）。
const postLyricsMinLength = 10;

String? validatePostForm({
  required String singerName,
  required String singName,
  required String lyrics,
  required int explanationLength,
  int lyricsLimit = postLyricsLimit,
  int explanationLimit = postExplanationLimit,
  int lyricsMinLength = postLyricsMinLength,
}) {
  if (singerName.trim().isEmpty || singName.trim().isEmpty) {
    return '曲を一覧から選んでください';
  }
  final text = lyrics.trim();
  if (text.isEmpty) return '歌詞の範囲を選んでください';
  if (lyricsMinLength > 0 && text.length < lyricsMinLength) {
    return '歌詞は$lyricsMinLength文字以上選んでください';
  }
  if (text.length > lyricsLimit) return '歌詞は$lyricsLimit文字以内で選んでください';
  if (explanationLength > explanationLimit) {
    return '思いは$explanationLimit文字以内にしてください';
  }
  return null;
}

bool shouldShowPostInFeed(Post post, String? currentUid) {
  if (currentUid != null && post.posterId == currentUid) return true;
  return post.text.trim().length >= postLyricsMinLength;
}
