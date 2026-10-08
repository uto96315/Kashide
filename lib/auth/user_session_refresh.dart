import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// アカウント切り替え・ログアウト後にユーザー依存の状態をリセットする。
void refreshUserSession(
  Ref ref, {
  /// 追加ログイン後はマイページ(3)へ。通常はホーム(0)。
  int homeTabIndex = 0,
}) {
  ref.read(cardPreviewPlayerProvider).stop();
  ref.read(sessionRefreshKeyProvider.notifier).bump();
  ref.read(homeTabIndexProvider.notifier).setTab(homeTabIndex);
  ref.invalidate(blockListProvider);
  ref.invalidate(timelineProvider);
  ref.invalidate(homeProvider);
  ref.invalidate(myPageProvider);
  ref.invalidate(searchProvider);
  ref.invalidate(playlistProvider);
  ref.invalidate(notificationProvider);
  ref.invalidate(notificationInboxProvider);
  ref.read(pushTokenServiceProvider).syncForCurrentUser();
}

void refreshAfterAccountChange(
  WidgetRef ref, {
  int homeTabIndex = 0,
}) =>
    refreshUserSession(ref, homeTabIndex: homeTabIndex);
