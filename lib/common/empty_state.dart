import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.icon = Icons.music_note});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
      child: Column(
        children: [
          Icon(icon, size: 42, color: mainColor),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF8E8E93)),
          ),
        ],
      ),
    );
  }
}
