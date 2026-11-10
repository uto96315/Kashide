import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/common/kashide_theme.dart';
import 'package:str_gram_beta/common/block_user_actions.dart';
import 'package:str_gram_beta/common/empty_state.dart';
import 'package:str_gram_beta/common/lyric_post_card.dart';
import 'package:str_gram_beta/common/playlist_picker_sheet.dart';
import 'package:str_gram_beta/common/screen_top.dart';
import 'package:str_gram_beta/domain/post_domain.dart';
import 'package:str_gram_beta/post/post_validation.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/search/post_search_matcher.dart';

class SearchResultPage extends ConsumerWidget {
  const SearchResultPage(this.searchWord, this.themeColor, {super.key});

  final String searchWord;
  final Color themeColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(unifiedSearchProvider(searchWord));
    final timeline = ref.watch(timelineProvider);
    final blocked = ref.watch(blockListProvider).blockedIds;
    final visibleHits = model.hits
        .where(
          (h) =>
              !blocked.contains(h.post.posterId) &&
              shouldShowPostInFeed(h.post, timeline.uid),
        )
        .toList(growable: false);

    return Scaffold(
      backgroundColor: kashideGroupedBackground(context),
      body: Column(
        children: [
          ScreenTop(title: '「$searchWord」'),
          if (model.isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: mainColor),
              ),
            )
          else if (model.errorMessage != null)
            Expanded(child: EmptyState(message: model.errorMessage!))
          else if (visibleHits.isEmpty)
            const Expanded(
              child: EmptyState(
                message: '見つかりませんでした\n表記ゆれがある場合は別のキーワードも試してください',
              ),
            )
          else
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Text(
                        '${visibleHits.length}件'
                        '${model.itunesHintCount > 0 ? ' · Apple Musicの曲名・アーティストも参照' : ''}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final hit = visibleHits[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hit.matches.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    for (final m in hit.matches)
                                      _MatchChip(match: m),
                                  ],
                                ),
                              ),
                            LyricPostCard(
                              post: hit.post,
                              highlightQuery: searchWord,
                              menuItems: hit.post.posterId == timeline.uid
                                  ? const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('編集する'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('削除する'),
                                      ),
                                    ]
                                  : const [
                                      PopupMenuItem(
                                        value: 'report',
                                        child: Text('報告する'),
                                      ),
                                      PopupMenuItem(
                                        value: 'block',
                                        child: Text('ブロックする'),
                                      ),
                                    ],
                              onMenu: (value) async {
                                if (value == 'delete') {
                                  await timeline.deletePosts(hit.post.id);
                                  ref.invalidate(unifiedSearchProvider(searchWord));
                                } else if (value == 'report') {
                                  await timeline.reportPosts(hit.post.id);
                                } else if (value == 'block') {
                                  await blockUserFromFeed(
                                    context,
                                    ref,
                                    hit.post.posterId,
                                  );
                                  ref.invalidate(unifiedSearchProvider(searchWord));
                                }
                              },
                              onPlaylist: () => _pickPlaylist(
                                context,
                                ref,
                                timeline,
                                hit.post,
                              ),
                            ),
                          ],
                        );
                      },
                      childCount: visibleHits.length,
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> _pickPlaylist(
  BuildContext context,
  WidgetRef ref,
  dynamic timeline,
  Post post,
) async {
  await showPlaylistPickerSheet(
    context,
    playlists: timeline.playList,
    onSelect: (playlistId) async {
      await timeline.addToPlaylist(
        playlistId,
        post.artist,
        post.singName,
        post.youtubeLink,
        post.id,
      );
    },
    onCreate: (name) async {
      timeline.addPlaylistController.text = name;
      timeline.setNewName(name);
      await timeline.addNewPlaylist();
      await timeline.getPlayListData();
      timeline.addPlaylistController.text = '';
    },
  );
}

class _MatchChip extends StatelessWidget {
  const _MatchChip({required this.match});

  final PostSearchMatch match;

  String get _label => switch (match) {
        PostSearchMatch.lyrics => '歌詞',
        PostSearchMatch.artist => 'アーティスト',
        PostSearchMatch.songTitle => '曲名',
        PostSearchMatch.genre => 'ジャンル',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: mainColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: mainColor,
        ),
      ),
    );
  }
}
