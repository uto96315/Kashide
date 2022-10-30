import 'package:fcm_config/fcm_config.dart';
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


// 通知
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}


// main
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦固定
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  timeAgo.setLocaleMessages("ja", timeAgo.JaMessages()); // 〜分前で表示するため



  // 通知設定
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging messaging = FirebaseMessaging.instance; // 通知用

  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    announcement: true,
    badge: true,
    carPlay: true,
    criticalAlert: true,
    provisional: false,
    sound: true,
  );

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');
    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification.toString()}');
    }
  });
  debugPrint('通知可否：User granted permission: ${settings.authorizationStatus}');
  final token = await messaging.getToken();
  debugPrint("Token : $token");


  // run App
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kashide',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }
          if (snapshot.hasData) {
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
        "/post": (context) => PostPage(null),
        // "/editUserDetails": (context) => EditUserDetailsPage("", ""),
      },
    );
  }
}
