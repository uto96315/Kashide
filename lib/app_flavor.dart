/// 本番（App Store）と開発配布（Ad Hoc / 実機テスト）を別アプリとして共存させるためのフレーバー。
enum AppFlavor {
  prod,
  dev,
}

extension AppFlavorX on AppFlavor {
  bool get isDev => this == AppFlavor.dev;

  String get iosBundleId => isDev ? 'com.example.kashide.dev' : 'com.example.kashide';

  String get androidApplicationId =>
      isDev ? 'com.yuto.mabe.kashide.dev' : 'com.yuto.mabe.kashide';

  String get displayName => isDev ? 'Kashide Dev' : 'Kashide';
}
