

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class TopModel extends ChangeNotifier {

  var user = FirebaseAuth.instance.currentUser;

  void accountCheck() {
    print(user?.uid ?? "no user data.");
  }
}