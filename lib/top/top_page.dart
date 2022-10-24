import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/login/login_page.dart';

class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: mainColor
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 100),
              SizedBox(
                  width: MediaQuery.of(context).size.width*0.6,
                  height: MediaQuery.of(context).size.width*0.6,
                  child: Image.asset("images/logo_white.png", fit: BoxFit.contain)
              ),
              OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, "/login");
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(top: 20, bottom: 20, right: 50, left: 50),
                    child: Text("はじめる", style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: mainColor )),
                  ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
