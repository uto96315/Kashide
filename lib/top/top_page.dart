import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/login/login_page.dart';

class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox( height: 100 ),
            TextButton(
                onPressed: (){
                  Navigator.pushNamed(context, "/login");
                },
                child: const Text("はじめる")
            ),
            const SizedBox( height: 100 ),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}