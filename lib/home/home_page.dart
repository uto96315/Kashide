import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/timeline/timeline_page.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/top/top_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        bottomNavigationBar: Container(
          color: Colors.white,
          height: 80,
          child: const Padding(
            padding: EdgeInsets.only(right: 20, left: 20),
            child: TabBar(
              labelColor: mainColor,
              indicatorColor: mainColor,
              unselectedLabelColor: Colors.blueGrey,
              tabs: [
                Tab(icon: Icon(Icons.home, size: 25), child: Text("ホーム", style: TextStyle(fontSize: 10))),
                Tab(icon: Icon(Icons.search, size: 25), child: Text("探す", style: TextStyle(fontSize: 10))),
                Tab(icon: Icon(Icons.notifications, size: 25), child: Text("通知", style: TextStyle(fontSize: 10))),
                Tab(icon: Icon(Icons.person, size: 25), child: Text("アカウント", style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
        ),
        body: const Center(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [
              TimelinePage(),
              SearchPage(),
              NotificationPage(),
              MyPage(),
            ],
          ),
        ),
      ),
    );
  }
}
