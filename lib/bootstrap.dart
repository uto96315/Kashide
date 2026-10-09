import 'package:app_badge_plus/app_badge_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/auth/account_switch_providers.dart';
import 'package:flutter/services.dart';
import 'package:str_gram_beta/app_flavor.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  const flavorKey = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  DefaultFirebaseOptions.flavor =
      flavorKey == 'dev' ? AppFlavor.dev : AppFlavor.prod;
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint("Handling a background message: ${message.messageId}");
}

Future<void> bootstrap(AppFlavor flavor) async {
  DefaultFirebaseOptions.flavor = flavor;

  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  timeAgo.setLocaleMessages("ja", timeAgo.JaMessages());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  final messaging = FirebaseMessaging.instance;

  final settings = await messaging.requestPermission(
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
  try {
    final token = await messaging.getToken();
    debugPrint("Token : $token");
  } catch (e) {
    debugPrint('FCM token を取得できませんでした: $e');
  }

  try {
    await AppBadgePlus.updateBadge(0);
  } catch (e) {
    debugPrint(e.toString());
  }

  runApp(ProviderScope(child: KashideApp(flavor: flavor)));
}

class KashideApp extends ConsumerWidget {
  const KashideApp({super.key, required this.flavor});

  final AppFlavor flavor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountSwitching = ref.watch(accountSwitchInProgressProvider);
    return MaterialApp(
      title: flavor.displayName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: mainColor),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          centerTitle: true,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            elevation: 0,
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      builder: (context, child) {
        if (!flavor.isDev || child == null) return child ?? const SizedBox.shrink();
        return Banner(
          message: 'DEV',
          location: BannerLocation.topEnd,
          color: const Color(0xFFE53935),
          child: child,
        );
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: mainColor)),
            );
          }
          if (snapshot.hasData) {
            return HomePage();
          }
          if (accountSwitching) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: mainColor)),
            );
          }
          return const TopPage();
        },
      ),
      routes: {
        "/login": (context) => const LoginPage(),
        "/register": (context) => const RegisterPage(),
        "/home": (context) => HomePage(),
        "/first": (context) => const TimelinePage(),
        "/search": (context) => const SearchPage(),
        "/notification": (context) => const NotificationPage(),
        "/myPage": (context) => const MyPage(),
        "/registerUserDetails": (context) => const RegisterUserDetailsPage(),
        "/post": (context) => const PostPage(null, analyticsSource: 'named_route_post'),
      },
    );
  }
}
