import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class PostFab extends StatelessWidget {
  const PostFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: mainColor,
      elevation: 4,
      child: const Icon(Icons.add, color: Colors.white, size: 28),
    );
  }
}
