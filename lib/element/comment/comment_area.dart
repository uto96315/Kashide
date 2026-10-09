import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/app_avatar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/providers.dart';
import '../../domain/comment_domain.dart';

class CommentArea extends ConsumerWidget {
  const CommentArea(this.id, this.commentsList, {super.key});

  final String id;
  final List<CommentDomain> commentsList;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(postDetailProvider(id));
    if (commentsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('まだコメントはありません', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8E93))),
      );
    }
    return Column(
      children: commentsList.map((comment) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E5EA)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(
                    imageUrl: comment.commenterImageUrl,
                    radius: 16,
                    backgroundColor: const Color(0xFFE5E5EA),
                    iconColor: const Color(0xFF8E8E93),
                    iconSize: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(comment.commenterName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                            ),
                            Text(comment.commentedAt, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(comment.comment, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF3A3A3C))),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.more_horiz, size: 18, color: Color(0xFF8E8E93)),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        final ok = await model.deleteComment(id, comment.id);
                        if (!ok && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('コメントを削除できませんでした')),
                          );
                        }
                      } else if (value == 'report') {
                        await model.reportComment(id, comment.id, comment.comment);
                      }
                    },
                    itemBuilder: (_) => comment.commenterId == model.uid
                        ? const [PopupMenuItem(value: 'delete', child: Text('削除する'))]
                        : const [PopupMenuItem(value: 'report', child: Text('報告する'))],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
