import 'package:flutter/material.dart';
import 'package:str_gram_beta/timeline/timeline_page.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/top/top_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        bottomNavigationBar: Container(
          color: Colors.white,
          height: 80,
          child: const Padding(
            padding: EdgeInsets.only(right: 20, left: 20),
            child: TabBar(
              labelColor: Colors.blue,
              indicatorColor: Colors.blue,
              unselectedLabelColor: Colors.blueGrey,
              tabs: [
                Tab(icon: Icon(Icons.home), text: "ホーム"),
                Tab(icon: Icon(Icons.favorite), text: "MVP"),
                Tab(icon: Icon(Icons.search), text: "検索"),
                Tab(icon: Icon(Icons.notifications), text: "通知"),
                Tab(icon: Icon(Icons.person), text: "ページ"),
              ],
            ),
          ),
        ),
        body: const Center(
          child: TabBarView(
            children: [
              TimelinePage(),
              TopPage(),
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
