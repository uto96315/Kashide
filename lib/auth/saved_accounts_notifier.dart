import 'package:flutter/foundation.dart';

import 'account_switch_service.dart';
import 'saved_account.dart';

class SavedAccountsNotifier extends ChangeNotifier {
  SavedAccountsNotifier(this._service);

  final AccountSwitchService _service;

  List<SavedAccount> accounts = [];
  bool ready = false;

  Future<void> reload() async {
    accounts = await _service.loadSaved();
    ready = true;
    notifyListeners();
  }

  Future<void> syncAfterAuth({required String email, required String password}) async {
    accounts = await _service.persistAfterAuth(email: email, password: password);
    ready = true;
    notifyListeners();
  }

  Future<void> removeFromDevice(String uid) async {
    accounts = await _service.removeFromDevice(uid);
    notifyListeners();
  }

  Future<void> ensureCurrentListed() async {
    accounts = await _service.ensureCurrentAccountListed();
    ready = true;
    notifyListeners();
  }
}
