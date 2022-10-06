

class Post {
  Post(this.artist, this.singName, this.text, this.posterId, this.likeCount, this.tags, this.userName, this.userImageUrl);

  String artist;
  String singName;
  String text;
  String posterId;
  int likeCount;
  List<dynamic> tags;
  String userName;
  String userImageUrl;
}