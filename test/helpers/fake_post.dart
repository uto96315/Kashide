import 'package:str_gram_beta/domain/post_domain.dart';

Post fakePost({
  String id = 'post-1',
  String text = '砂漠の街に住んでても',
  String artist = 'Mr.Children',
  String singName = '365日',
  List<String> genres = const ['恋愛ソング', 'JPOP'],
  int likedCount = 0,
  int commentCount = 0,
  String explanation = '素敵な表現です',
  String youtubeLink = 'https://music.apple.com/jp/album/example',
}) {
  return Post(
    artist,
    singName,
    text,
    'user-1',
    likedCount,
    genres,
    'papy',
    '',
    '約1時間前',
    id,
    commentCount,
    explanation,
    youtubeLink,
  );
}
