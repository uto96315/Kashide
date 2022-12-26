import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/home/home_model.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/notification/notification_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/timeline/timeline_page.dart';
import 'package:url_launcher/url_launcher.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeModel>(
      create: (_) => HomeModel()..getNowVersions()..getLatestVersions(),
      child: Consumer<HomeModel>(builder: (context, model, child) {
        return model.needToUpDate
            ? Scaffold(
            body: Center(
                child: Column(
                  children: [
                    const SizedBox( height: 300 ),
                    const Text(
                        "新しいバージョンがリリースされました。\nアップデートをお願い致します。",
                        style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox( height: 100 ),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                        ),
                        onPressed: ()async{
                          await launch(model.updateUrl ?? "");
                        },
                        child: const Padding(
                          padding: EdgeInsets.only( top: 15, bottom: 15, right: 10, left: 10),
                          child: Text("Storeからアップデートする"),
                        )
                    )
                  ],
                )
            ))
            : DefaultTabController(
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
                          Tab(
                              icon: Icon(Icons.home, size: 25),
                              child:
                                  Text("ホーム", style: TextStyle(fontSize: 10))),
                          Tab(
                              icon: Icon(Icons.search, size: 25),
                              child:
                                  Text("探す", style: TextStyle(fontSize: 10))),
                          Tab(
                              icon: Icon(Icons.notifications, size: 25),
                              child:
                                  Text("通知", style: TextStyle(fontSize: 10))),
                          Tab(
                              icon: Icon(Icons.person, size: 25),
                              child: Text("アカウント",
                                  style: TextStyle(fontSize: 10))),
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
      }),
    );
  }
}
