

class Post {
  Post(this.artist, this.singName,
      this.text, this.posterId,
      this.likeCount, this.genres,
      this.userName, this.userImageUrl,
      this.createdAt, this.id
      );

  String artist;
  String singName;
  String text;
  String posterId;
  int likeCount;
  List<dynamic> genres;
  String userName;
  String userImageUrl;
  String createdAt;
  String id;
}