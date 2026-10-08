import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountSwitchInProgressNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final accountSwitchInProgressProvider =
    NotifierProvider<AccountSwitchInProgressNotifier, bool>(AccountSwitchInProgressNotifier.new);
