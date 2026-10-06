import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/genre_browse_scene.dart';

/// 検索タブのジャンルタイル（写真＋下部だけ薄いスクリム）。
class SearchGenreTile extends StatelessWidget {
  const SearchGenreTile({super.key, required this.genre, required this.onTap});

  final String genre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final asset = genreBrowseImageFor(genre);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E5EA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: 1.65,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.92,
                child: Image.asset(asset, fit: BoxFit.cover),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.38),
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.06),
                    ],
                    stops: const [0, 0.5, 1],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    genre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C1E),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
