String genreEmptyMessage(String condition) {
  switch (condition) {
    case 'artist':
      return 'この歌手の投稿はまだありません。';
    case 'singName':
      return 'この曲の投稿はまだありません。';
    case 'poster':
      return 'この人の投稿はまだありません。';
    default:
      return 'このジャンルの投稿はまだありません。';
  }
}
