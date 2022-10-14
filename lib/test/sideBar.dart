

import 'package:flutter/material.dart';

class SidebarExample extends StatelessWidget {
  SidebarExample({Key? key}) : super(key: key);

  var sideBarKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: sideBarKey,
      body: Center(
        child: TextButton(
            onPressed: (){
              sideBarKey.currentState!.openEndDrawer(); // これがサイドバーを開く処理
            },
            child: const Text("サイドバーを開く")),
      ),

      // ここからサイドバー
      endDrawer: Drawer(  // 変更箇所
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("メニュー1"),
              onTap: (){
                // ここにメニュータップ時の処理を記述
              },
            ),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text("メニュー2"),
              onTap: (){},
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text("メニュー3"),
              onTap: (){},
            )
          ],
        ),
      ),
    );
  }
}
