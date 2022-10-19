import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/postDetail/post_detail_model.dart';
import '../../domain/comment_domain.dart';
import 'comment_model.dart';



class CommentArea extends StatelessWidget {
  CommentArea(this.id,this.commentsList, {super.key});
  
  String id;
  List<CommentDomain> commentsList;
  // Future(String, String, String) reportComment; // todo: ここをコールバックに変更する

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Consumer<PostDetailModel>(builder: (context, model, child) {
          return Column(
            children: commentsList.map((comment){
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width*0.8,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // ユーザー画像
                              Row(
                                children: [
                                  Container(
                                      width: MediaQuery.of(context).size.width*0.1,
                                      height: MediaQuery.of(context).size.width*0.1,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey),
                                        borderRadius: BorderRadius.circular(50),
                                        color: Colors.grey.shade200,
                                        image: (comment.commenterImageUrl != "" || comment.commenterImageUrl.isNotEmpty)
                                            ? DecorationImage(
                                            image: NetworkImage(comment.commenterImageUrl), fit: BoxFit.cover)
                                            : null,
                                      ),
                                      child: (comment.commenterImageUrl != "")
                                          ? null
                                          : const Icon(Icons.person)
                                  ),
                                  const SizedBox( width: 10 ),

                                  // ユーザーネーム
                                  Text(comment.commenterName, style: const TextStyle( fontSize: 15, fontWeight: FontWeight.bold )),
                                ],
                              ),

                              Text(comment.commentedAt, style: const TextStyle( color: Colors.grey )),
                            ],
                          ),
                        ),

                        // 報告及び削除ボタン
                        SizedBox(
                          width: 20,
                          child: PopupMenuButton(
                              icon: const Icon(Icons.more_horiz),
                              onSelected: (value)async{
                                //　削除処理
                                if(value == "delete"){
                                  try{
                                    await model.deleteComment(id, comment.id);
                                  } catch(e) {
                                    debugPrint(e.toString());
                                  }
                                }
                                //　報告処理
                                if(value == "report") {
                                  try{
                                    await model.reportComment(id, comment.id, comment.comment);
                                  } catch(e) {
                                    debugPrint(e.toString());
                                  }
                                }
                              },
                              itemBuilder: (BuildContext context) => [
                                (comment.commenterId == model.uid )
                                    ? const PopupMenuItem(
                                  value: "delete",
                                  child: Text("削除"),
                                )
                                    : const PopupMenuItem(
                                  value: "report",
                                  child: Text("報告"),
                                ),
                              ]
                          ),
                        )
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
      );
  }
}