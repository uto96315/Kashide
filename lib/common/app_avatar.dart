import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/network_image_utils.dart';

/// プロフィール画像（メモリ・ディスクキャッシュ + 表示サイズに合わせたデコード）。
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    this.backgroundColor = const Color(0xFFE7E9EA),
    this.iconColor = const Color(0xFF536471),
    this.iconSize,
  });

  final String? imageUrl;
  final double radius;
  final Color backgroundColor;
  final Color iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final url = normalizeNetworkImageUrl(imageUrl);
    final diameter = radius * 2;
    final pixelSize = (diameter * MediaQuery.devicePixelRatioOf(context)).round().clamp(48, 256);

    if (url == null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(Icons.person, size: iconSize ?? radius, color: iconColor),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: diameter,
          height: diameter,
          fit: BoxFit.cover,
          memCacheWidth: pixelSize,
          memCacheHeight: pixelSize,
          maxWidthDiskCache: pixelSize,
          maxHeightDiskCache: pixelSize,
          fadeInDuration: const Duration(milliseconds: 120),
          placeholder: (_, __) => Icon(Icons.person, size: iconSize ?? radius * 0.9, color: iconColor),
          errorWidget: (_, __, ___) => Icon(Icons.person, size: iconSize ?? radius * 0.9, color: iconColor),
        ),
      ),
    );
  }
}
