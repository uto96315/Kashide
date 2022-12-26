import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_model.dart';



class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NotificationModel>(
      create: (_) => NotificationModel()..getToken()..requestReview(),
      child: Scaffold(
        body: Center(
          child: Consumer<NotificationModel>(builder: (context, model, child) {
            return const Text("現在通知はありません。");
          }),
        ),
      ),
    );
  }
}
