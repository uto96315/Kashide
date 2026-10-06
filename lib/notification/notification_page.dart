import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';

class NotificationPage extends ConsumerWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationProvider);
    return const Scaffold(
      body: Column(
        children: [
          const ScreenTop(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 48, color: mainColor),
                  SizedBox(height: 12),
                  Text('新しい通知はありません'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
