import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// アカウント切り替え・ログアウト後にユーザー依存の状態をリセットする。
void refreshAfterAccountChange(WidgetRef ref) {
  ref.read(cardPreviewPlayerProvider).stop();
  ref.read(homeTabIndexProvider.notifier).setTab(0);
  ref.invalidate(blockListProvider);
  ref.invalidate(homeProvider);
  ref.invalidate(myPageProvider);
  ref.invalidate(searchProvider);
  ref.invalidate(playlistProvider);
  ref.invalidate(notificationProvider);
}
