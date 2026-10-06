import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import 'package:str_gram_beta/providers.dart';

class LikedPostsPage extends ConsumerWidget {
  const LikedPostsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(likedPostsProvider);
    return Scaffold(
      body: Column(
        children: [
          const ScreenTop(),
          Expanded(
            child: model.loading
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : model.posts.isEmpty
                    ? const EmptyState(icon: Icons.favorite_border, message: 'まだいいねした歌詞がありません')
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: model.posts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final post = model.posts[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => PostDetailPage(post.id, false)));
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFFFD6E4)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.45, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 10),
                                    Text(post.singName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(post.artist, style: const TextStyle(color: Color(0xFF8E8E93))),
                                    const SizedBox(height: 8),
                                    Text(post.userName, style: const TextStyle(fontSize: 13, color: Color(0xFF3A3A3C))),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
