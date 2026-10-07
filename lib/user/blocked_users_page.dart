import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/app_dialog.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/providers.dart';

class BlockedUsersPage extends ConsumerWidget {
  const BlockedUsersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockList = ref.watch(blockListProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: Column(
        children: [
          const ScreenTop(title: 'ブロック中のユーザー'),
          Expanded(
            child: !blockList.ready
                ? const Center(child: CircularProgressIndicator(color: mainColor))
                : blockList.entries.isEmpty
                    ? const EmptyState(
                        icon: CupertinoIcons.hand_raised,
                        message: 'ブロックしているユーザーはいません',
                        detail: 'タイムラインのメニューからブロックできます。',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: blockList.entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = blockList.entries[index];
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            child: ListTile(
                              title: Text(
                                entry.userName,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: const Text('投稿が表示されません'),
                              trailing: TextButton(
                                onPressed: () async {
                                  final ok = await showAppConfirm(
                                    context,
                                    title: 'ブロック解除',
                                    message: '「${entry.userName}」のブロックを解除しますか？',
                                    confirm: '解除する',
                                  );
                                  if (!ok) return;
                                  await ref.read(blockListProvider).unblockUser(entry.userId);
                                  ref.invalidate(likedPostsProvider);
                                  ref.invalidate(timelineProvider);
                                },
                                child: const Text('解除', style: TextStyle(color: mainColor, fontWeight: FontWeight.w700)),
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
