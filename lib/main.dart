import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:str_gram_beta/editUserDetails/edit_user_details_page.dart';
import 'package:str_gram_beta/first/first_page.dart';
import 'package:str_gram_beta/home/home_page.dart';
import 'package:str_gram_beta/login/login_page.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/register/register_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/top/top_page.dart';
import 'registerUserDetails/register_user_details_page.dart';
import 'firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦固定
  ]);
  runApp(const MyApp());
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StrGram',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      // 以下にルーティングを記載
      routes: {
        "/": (context) => const TopPage(),
        "/login": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
        "/home": (context) => HomePage(),
        "/first": (context) => const FirstPage(),
        "/search": (context) => const SearchPage(),
        "/notification": (context) => const NotificationPage(),
        "/myPage": (context) => const MyPage(),
        "/registerUserDetails": (context) => const RegisterUserDetailsPage(),
        // "/editUserDetails": (context) => EditUserDetailsPage("", ""),
      },
    );
  }
}


