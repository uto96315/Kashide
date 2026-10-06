/// スワイプカード背景画像のパスを、投稿ジャンルから決める。
String swipeCardSceneFor(Iterable<String> genres) {
  final text = genres.join(' ');
  if (text.contains('ジャニーズ') || text.contains('アイドル')) return 'images/card_johnnys.jpg';
  if (text.contains('男性目線')) return 'images/card_male.jpg';
  if (text.contains('女性目線')) return 'images/card_female.jpg';
  if (text.contains('LGBTQ')) return 'images/card_lgbtq.jpg';
  if (text.contains('ペット')) return 'images/card_pet.jpg';
  if (text.contains('人生')) return 'images/card_life.jpg';
  if (text.contains('失恋') || text.contains('切ない') || text.contains('悲し')) return 'images/card_sad.jpg';
  if (text.contains('ロック')) return 'images/card_rock.jpg';
  if (text.contains('R&B') || text.contains('ソウル')) return 'images/card_rnb.jpg';
  if (text.contains('懐')) return 'images/card_retro.jpg';
  if (text.contains('洋楽')) return 'images/card_western.jpg';
  if (text.contains('恋愛')) return 'images/card_love.jpg';
  if (text.contains('青春') || text.contains('元気') || text.contains('勇気')) return 'images/card_youth.jpg';
  if (text.contains('JPOP') || text.contains('J-POP')) return 'images/card_jpop.jpg';
  return 'images/card_other.jpg';
}
