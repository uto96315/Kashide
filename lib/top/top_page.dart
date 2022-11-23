import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/login/login_page.dart';
import 'package:str_gram_beta/top/top_model.dart';


class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TopModel>(
      create: (_) => TopModel(),
      child: Scaffold(
        body: Center(
          child: Consumer<TopModel>(builder: (context, model, child) {
            return Container(
              decoration: const BoxDecoration(
                  color: Colors.white60
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 100),
                    SizedBox(
                        width: MediaQuery.of(context).size.width*0.6,
                        height: MediaQuery.of(context).size.width*0.6,
                        child: Image.asset("images/splash_new.png", fit: BoxFit.contain)
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, "/login");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.only(top: 20, bottom: 20, right: 50, left: 50),
                        child: Text("はじめる", style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white )),
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            );;
          }),
        ),
      ),
    );
  }
}



