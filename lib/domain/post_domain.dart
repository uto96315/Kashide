

class Post {
  Post(this.artist, this.singName,
      this.text, this.posterId,
      this.likedCount, this.genres,
      this.userName, this.userImageUrl,
      this.createdAt, this.id, this.commentCount
      );

  String artist;
  String singName;
  String text;
  String posterId;
  int likedCount;
  List<dynamic> genres;
  String userName;
  String userImageUrl;
  String createdAt;
  String id;
  int commentCount;
}