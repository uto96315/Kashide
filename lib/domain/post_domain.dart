

class Post {
  Post(this.artist, this.singName,
      this.text, this.posterId,
      this.likedCount, this.genres,
      this.userName, this.userImageUrl,
      this.createdAt, this.id, this.commentCount,
      this.explanation, this.youtubeLink,
      );

  String explanation;
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
  String youtubeLink;
  int commentCount;
}