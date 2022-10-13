


import 'package:cloud_firestore/cloud_firestore.dart';

class CommentDomain {
  CommentDomain(
      this.id,
      this.comment,
      this.commentedAt,
      this.commenterName,
      this.commenterImageUrl
      );

  String id;
  String comment;
  String commenterName;
  String commenterImageUrl;
  String commentedAt;
}