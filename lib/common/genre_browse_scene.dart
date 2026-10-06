/// 検索 Browse タイル用。既存カード画像をジャンル名でできるだけ分散して割り当て。
String genreBrowseImageFor(String genre) {
  const map = {
    '恋愛ソング': 'images/card_love.jpg',
    '失恋ソング': 'images/card_sad.jpg',
    '懐メロ': 'images/card_retro.jpg',
    'JPOP': 'images/card_jpop.jpg',
    '男性目線': 'images/card_male.jpg',
    '女性目線': 'images/card_female.jpg',
    'LGBTQ': 'images/card_lgbtq.jpg',
    '洋楽': 'images/card_western.jpg',
    '人生': 'images/card_life.jpg',
    'ペット': 'images/card_pet.jpg',
    'ロック': 'images/card_rock.jpg',
    'ジャニーズ': 'images/card_johnnys.jpg',
    '元気になれる曲': 'images/card_youth.jpg',
    'R&B ソウル': 'images/card_rnb.jpg',
    'アイドル': 'images/card_jpop.jpg',
    '青春': 'images/card_retro.jpg',
    '勇気': 'images/card_sad.jpg',
    'その他': 'images/card_other.jpg',
  };
  final hit = map[genre];
  if (hit != null) return hit;

  const pool = [
    'images/card_love.jpg',
    'images/card_sad.jpg',
    'images/card_retro.jpg',
    'images/card_jpop.jpg',
    'images/card_rock.jpg',
    'images/card_rnb.jpg',
    'images/card_youth.jpg',
    'images/card_western.jpg',
    'images/card_johnnys.jpg',
    'images/card_other.jpg',
    'images/card_male.jpg',
    'images/card_female.jpg',
    'images/card_lgbtq.jpg',
    'images/card_life.jpg',
    'images/card_pet.jpg',
  ];
  return pool[genre.hashCode.abs() % pool.length];
}
