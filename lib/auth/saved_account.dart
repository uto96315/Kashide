import 'anonymous_user.dart' show anonymousDisplayName, anonymousIndexSuffix, isAnonymousPlaceholderEmail;

/// 端末に保持するログイン済みアカウント（切り替え用）。
class SavedAccount {
  const SavedAccount({
    required this.uid,
    required this.email,
    required this.password,
    this.displayName,
    this.iconUrl,
  });

  final String uid;
  final String email;
  final String password;
  final String? displayName;
  final String? iconUrl;

  /// メールのない匿名ユーザーを端末一覧に載せるためのプレースホルダ。
  static String anonymousPlaceholderEmail(String uid) => 'anonymous+$uid@accounts.kashide.app';

  bool get isAnonymousPlaceholder => isAnonymousPlaceholderEmail(email);

  String get label {
    if (isAnonymousPlaceholder) return anonymousDisplayName;
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return email;
  }

  /// ログイン時にパスワードを保存済みならワンタップ切替できる。
  bool get canQuickSwitch => password.isNotEmpty || isAnonymousPlaceholder;

  SavedAccount copyWith({
    String? uid,
    String? email,
    String? password,
    String? displayName,
    String? iconUrl,
  }) {
    return SavedAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      iconUrl: iconUrl ?? this.iconUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
        if (iconUrl != null) 'iconUrl': iconUrl,
      };

  static String? _normalizeIcon(String? url) {
    if (url == null) return null;
    final t = url.trim();
    if (t.isEmpty || t == 'null') return null;
    return t;
  }

  /// アカウント一覧での表示名（匿名は 匿名ユーザー①…）。
  static String listLabel(List<SavedAccount> accounts, SavedAccount account) {
    if (!account.isAnonymousPlaceholder) return account.label;
    var anonIndex = 0;
    for (final a in accounts) {
      if (!a.isAnonymousPlaceholder) continue;
      anonIndex++;
      if (a.uid == account.uid) {
        return '$anonymousDisplayName${anonymousIndexSuffix(anonIndex)}';
      }
    }
    return anonymousDisplayName;
  }

  static SavedAccount? fromJson(Map<String, dynamic> json) {
    final uid = json['uid'] as String?;
    final email = json['email'] as String?;
    if (uid == null || email == null) return null;
    return SavedAccount(
      uid: uid,
      email: email,
      password: json['password'] as String? ?? '',
      displayName: json['displayName'] as String?,
      iconUrl: _normalizeIcon(json['iconUrl'] as String?),
    );
  }
}
