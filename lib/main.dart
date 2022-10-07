import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:str_gram_beta/timeline/timeline_page.dart';
import 'package:str_gram_beta/home/home_page.dart';
import 'package:str_gram_beta/login/login_page.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/post/post_page.dart';
import 'package:str_gram_beta/register/register_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/top/top_page.dart';
import 'registerUserDetails/register_user_details_page.dart';
import 'firebase_options.dart';
import 'package:timeago/timeago.dart' as timeAgo;

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦固定
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  timeAgo.setLocaleMessages("ja", timeAgo.JaMessages()); // 〜分前で表示するため
  runApp(const MyApp());
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

      home: StreamBuilder<User?> (
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if(snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if( snapshot.hasData) {
            return HomePage();
          }

          return TopPage();
        },
      ),

      // 以下にルーティングを記載
      routes: {
        // "/": (context) => const TopPage(), // homeを指定した場合には不要になる
        "/login": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
        "/home": (context) => HomePage(),
        "/first": (context) => const TimelinePage(),
        "/search": (context) => const SearchPage(),
        "/notification": (context) => const NotificationPage(),
        "/myPage": (context) => const MyPage(),
        "/registerUserDetails": (context) => const RegisterUserDetailsPage(),
        "/post": (context) => const PostPage(),
        // "/editUserDetails": (context) => EditUserDetailsPage("", ""),
      },
    );
  }
}


