import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/mypage/my_page.dart';
import 'package:str_gram_beta/playlist/playlist_page.dart';
import 'package:str_gram_beta/search/search_page.dart';
import 'package:str_gram_beta/common/home_tab_bar.dart';
import 'package:str_gram_beta/post/post_page.dart';
import 'package:str_gram_beta/timeline/timeline_page.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pushTokenServiceProvider).syncForCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = ref.watch(homeProvider);
    if (!model.versionChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: mainColor)),
      );
    }
    if (model.needToUpDate) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '新しいバージョンがリリースされました。\nアップデートをお願いします。',
                  style: TextStyle(fontSize: 16, height: 1.5),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: () async {
                    final url = model.updateUrl;
                    if (url != null && url.isNotEmpty) {
                      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    }
                  },
                  child: const Text('Storeからアップデートする'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final tabIndex = ref.watch(homeTabIndexProvider);
    final sessionKey = ref.watch(sessionRefreshKeyProvider);
    final pages = [
      TimelinePage(key: ValueKey('home-timeline-$sessionKey')),
      SearchPage(key: ValueKey('home-search-$sessionKey')),
      PlaylistPage(key: ValueKey('home-playlist-$sessionKey')),
      MyPage(key: ValueKey('home-mypage-$sessionKey')),
    ];
    return Scaffold(
      body: IndexedStack(index: tabIndex, children: pages),
      bottomNavigationBar: HomeTabBar(
        index: tabIndex,
        onChanged: (index) => ref.read(homeTabIndexProvider.notifier).setTab(index),
        onPost: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PostPage(null, analyticsSource: 'home_create_button'),
            ),
          );
        },
      ),
    );
  }
}
