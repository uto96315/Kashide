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
            const SizedBox(height: 100),
            OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, "/login");
                },
                child: const Padding(
                  padding: EdgeInsets.only(top: 20, bottom: 20, right: 50, left: 50),
                  child: Text("はじめる", style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold )),
                )),
            const SizedBox(height: 100),
          ],
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
