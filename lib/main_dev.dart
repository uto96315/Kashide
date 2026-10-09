import 'package:str_gram_beta/app_flavor.dart';
import 'package:str_gram_beta/bootstrap.dart';

/// 開発・配布テスト用（Bundle ID が本番と別なので App Store 版と共存できる）。
void main() => bootstrap(AppFlavor.dev);
