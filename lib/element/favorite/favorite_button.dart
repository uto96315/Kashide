import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/providers.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton(this.postId, this.likedCount, {super.key, this.compact = false});

  final String postId;
  final int? likedCount;
  final bool compact;

  static const _muted = Color(0xFF536471);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(favoriteProvider(FavoriteArgs(postId, likedCount)));
    final liked = model.isLiked;
    final color = liked ? mainColor : _muted;
    final icon = liked ? Icons.favorite_rounded : Icons.favorite_border_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await model.doLike(postId, likedCount ?? model.likedCount ?? 0);
          await model.checkLiked();
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 6, vertical: compact ? 10 : 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: compact ? 20 : 22),
              const SizedBox(width: 6),
              Text(
                '${model.likedCount}',
                style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
