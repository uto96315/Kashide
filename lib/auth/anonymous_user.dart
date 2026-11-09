import 'package:firebase_auth/firebase_auth.dart';

/// Firestore / UI 上の匿名ユーザー表示名。
const anonymousDisplayName = '匿名ユーザー';

bool isAnonymousPlaceholderEmail(String email) =>
    email.startsWith('anonymous+') && email.endsWith('@accounts.kashide.app');

/// 他ユーザー向け通知・投稿表示用（端末固有の番号や内部 ID を出さない）。
String publicDisplayName(String? userName) {
  final trimmed = userName?.trim() ?? '';
  if (trimmed.isEmpty) return anonymousDisplayName;
  if (isAnonymousPlaceholderEmail(trimmed)) return anonymousDisplayName;
  if (trimmed.startsWith('anonymous+') && trimmed.contains('@')) {
    return anonymousDisplayName;
  }
  if (RegExp(r'^匿名ユーザー[\s·．.][\w.\-]+$').hasMatch(trimmed)) {
    return anonymousDisplayName;
  }
  return trimmed;
}

String displayUserName(String? userName) => publicDisplayName(userName);

bool isAnonymousAuthUser(User? user) => user?.isAnonymous ?? false;

String anonymousIndexSuffix(int oneBased) {
  const circled = ['①', '②', '③', '④', '⑤', '⑥', '⑦', '⑧', '⑨', '⑩'];
  if (oneBased >= 1 && oneBased <= circled.length) return circled[oneBased - 1];
  return '($oneBased)';
}
