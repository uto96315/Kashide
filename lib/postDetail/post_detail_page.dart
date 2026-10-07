import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:str_gram_beta/element/comment/comment_area.dart';
import 'package:str_gram_beta/common/open_user_profile.dart';
import 'package:str_gram_beta/genre/genre_page.dart';
import 'package:str_gram_beta/common/listen_url_play_slot.dart';
import 'package:str_gram_beta/common/post_lyrics_text.dart';
import 'package:str_gram_beta/providers.dart';
import '../element/favorite/favorite_button.dart';

class PostDetailPage extends ConsumerWidget {
  const PostDetailPage(this.id, this.commentButtonTapped, {super.key});

  final String id;
  final bool commentButtonTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(postDetailProvider(id));
    final loading = model.postText == null;
    final icon = model.userIconUrl;
    final hasIcon = icon != null && icon.isNotEmpty && icon != 'null';
    final genres = model.genreList.whereType<String>().where((g) => g.isNotEmpty);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: Column(
          children: [
            const ScreenTop(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator(color: mainColor))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E5EA)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: const Color(0xFFE5E5EA),
                                        backgroundImage: hasIcon ? NetworkImage(icon) : null,
                                        child: hasIcon ? null : const Icon(Icons.person, color: Color(0xFF8E8E93)),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: model.posterId == null
                                              ? null
                                              : () {
                                                  openUserProfile(
                                                    context,
                                                    posterId: model.posterId!,
                                                    userName: model.posterName,
                                                  );
                                                },
                                          child: Text(
                                            model.posterName ?? '読み込み中...',
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if ((model.explanation ?? '').trim().isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(model.explanation!, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF3A3A3C))),
                                  ],
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F2F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: PostLyricsText(
                                      text: model.postText ?? '',
                                      segments: model.textSegments,
                                      style: const TextStyle(fontSize: 16, height: 1.5, fontWeight: FontWeight.w600, color: Color(0xFF1C1C1E)),
                                    ),
                                  ),
                                  if (genres.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        for (final genre in genres)
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(genre, 'genre')));
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF2F2F7),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(genre, style: const TextStyle(fontSize: 12, color: Color(0xFF3A3A3C))),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: model.singName == null
                                              ? null
                                              : () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(model.singName!, 'singName')));
                                                },
                                          child: Text(
                                            model.singName ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                                          ),
                                        ),
                                      ),
                                      const Text('  ·  ', style: TextStyle(color: Color(0xFF8E8E93))),
                                      Flexible(
                                        child: GestureDetector(
                                          onTap: model.singerName == null
                                              ? null
                                              : () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => GenrePage(model.singerName!, 'artist')));
                                                },
                                          child: Text(
                                            model.singerName ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Color(0xFF8E8E93)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ListenUrlPlaySlot(
                                        storedUrl: model.youtubeLink ?? '',
                                        artist: model.singerName ?? '',
                                        singName: model.singName ?? '',
                                        builder: (context, listenUrl) {
                                          if (listenUrl == null || listenUrl.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                                            onPressed: () {
                                              launchUrl(
                                                Uri.parse(listenUrl),
                                                mode: LaunchMode.externalApplication,
                                              );
                                            },
                                            icon: const Icon(Icons.play_circle_outline_rounded, size: 26, color: mainColor),
                                          );
                                        },
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.chat_bubble_outline, size: 22, color: Color(0xFF8E8E93)),
                                            const SizedBox(width: 6),
                                            Text('${model.commentsList.length}', style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.bar_chart_rounded, size: 22, color: Color(0xFF8E8E93)),
                                            const SizedBox(width: 6),
                                            Text('${model.viewCount}', style: const TextStyle(fontSize: 15, color: Color(0xFF8E8E93))),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      FavoriteButton(id, model.likedCount ?? 0),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Padding(
                            padding: EdgeInsets.only(left: 4, bottom: 8),
                            child: Text('コメント', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF3A3A3C))),
                          ),
                          CommentArea(id, model.commentsList),
                        ],
                      ),
                    ),
            ),
            _CommentComposerBar(
              userImageUrl: model.userImageUrl,
              controller: model.commentController,
              canSend: model.canComment,
              onChanged: model.checkComment,
              onSend: () async {
                await model.addComment(id);
                model.commentController.clear();
                if (!context.mounted) return;
                FocusScope.of(context).unfocus();
              },
              bottomInset: MediaQuery.paddingOf(context).bottom,
            ),
          ],
        ),
      ),
    );
  }
}

/// YouTube 風：入力は1つの pill、文字数は上限付近だけ横に小さく表示。
class _CommentComposerBar extends StatelessWidget {
  const _CommentComposerBar({
    required this.userImageUrl,
    required this.controller,
    required this.canSend,
    required this.onChanged,
    required this.onSend,
    required this.bottomInset,
  });

  final String? userImageUrl;
  final TextEditingController controller;
  final bool canSend;
  final void Function(String text) onChanged;
  final Future<void> Function() onSend;
  final double bottomInset;

  static const _maxLen = 200;

  @override
  Widget build(BuildContext context) {
    final hasImage = userImageUrl != null && userImageUrl!.isNotEmpty && userImageUrl != 'null';
    final len = controller.text.length;
    final showLimit = len >= 160;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFF3F4))),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFE5E5EA),
                backgroundImage: hasImage ? NetworkImage(userImageUrl!) : null,
                child: hasImage ? null : const Icon(Icons.person, size: 18, color: Color(0xFF8E8E93)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F2F7),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        maxLength: _maxLen,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                        decoration: const InputDecoration(
                          hintText: 'コメントを追加…',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: onChanged,
                      ),
                    ),
                    if (showLimit)
                      Padding(
                        padding: const EdgeInsets.only(right: 4, bottom: 8),
                        child: Text(
                          '$len/$_maxLen',
                          style: TextStyle(
                            fontSize: 11,
                            color: len >= _maxLen ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Material(
                color: canSend ? mainColor : const Color(0xFFE5E5EA),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: canSend ? onSend : null,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: canSend ? Colors.white : const Color(0xFFAEAEB2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
