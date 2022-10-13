import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'comment_model.dart';



class CommentArea extends StatelessWidget {
  CommentArea(this.id, {super.key});
  
  String id;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CommentModel>(
      create: (_) => CommentModel(id)..getComments(id),
      child: Scaffold(
        body: Center(
          child: Consumer<CommentModel>(builder: (context, model, child) {
            return Column(
              children: model.commentsList.map((comment){
                return Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // ユーザー画像
                              Container(
                                  width: MediaQuery.of(context).size.width*0.1,
                                  height: MediaQuery.of(context).size.width*0.1,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(50),
                                    color: Colors.grey.shade200,
                                    image: (comment.commenterImageUrl != "")
                                        ? DecorationImage(
                                        image: NetworkImage(
                                            comment.commenterImageUrl),
                                        fit: BoxFit.cover)
                                        : null,
                                  ),
                                  child: (comment.commenterImageUrl != "")
                                      ? null
                                      : const Icon(Icons.person)
                              ),
                              const SizedBox( width: 10 ),
                              Text(comment.commenterName, style: const TextStyle( fontSize: 15 )),
                            ],
                          ),
                          Text(comment.commentedAt), // 時間
                        ],
                      ),
                    ),

                    const SizedBox( height: 10 ),

                    // コメント本文
                    SizedBox(
                      width: MediaQuery.of(context).size.width*0.8,
                        child: Text(comment.comment, textAlign: TextAlign.left, style: const TextStyle(fontSize: 16, height: 1.5),)
                    ),

                    const SizedBox( height: 5 ),

                    const Divider( color: Colors.black54 )
                  ],
                );
              }).toList(),
            );
          }),
        ),
      ),
    );
  }
}