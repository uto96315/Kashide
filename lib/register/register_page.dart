import 'package:flutter/material.dart';
import 'package:str_gram_beta/login/login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginPage(startWithRegister: true);
  }
}
