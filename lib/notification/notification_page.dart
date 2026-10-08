import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/notifications/app_notification.dart';
import 'package:str_gram_beta/postDetail/post_detail_page.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationInboxProvider).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(notificationInboxProvider);

    return Scaffold(
      body: Column(
        children: [
          ScreenTop(
            trailing: inbox.unreadCount > 0 && !inbox.loading && inbox.error == null
                ? TextButton(
                    onPressed: () => ref.read(notificationInboxProvider).markAllRead(),
                    child: const Text('すべて既読'),
                  )
                : null,
          ),
          Expanded(
            child: inbox.loading
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : inbox.error != null
                    ? Center(child: Text(inbox.error!))
                    : inbox.items.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.notifications_none, size: 48, color: mainColor),
                                SizedBox(height: 12),
                                Text('新しい通知はありません'),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            color: mainColor,
                            onRefresh: () => ref.read(notificationInboxProvider).load(),
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: inbox.items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = inbox.items[index];
                                return _NotificationTile(
                                  item: item,
                                  onTap: () => _open(context, item),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context, AppNotification item) async {
    await ref.read(notificationInboxProvider).markRead(item.id);
    if (!context.mounted || item.postId.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(item.postId, false)),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final timeLabel = item.createdAt == null
        ? ''
        : timeago.format(item.createdAt!, locale: 'ja');
    return Material(
      color: item.read ? Colors.white : const Color(0xFFFFF7F8),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                item.type == 'like'
                    ? Icons.favorite_rounded
                    : item.type == 'comment'
                        ? Icons.chat_bubble_outline_rounded
                        : Icons.notifications_outlined,
                color: mainColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F1419),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(fontSize: 14, height: 1.35, color: Color(0xFF536471)),
                    ),
                    if (timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(timeLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
