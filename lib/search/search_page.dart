import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/providers.dart';
import 'package:str_gram_beta/search/search_model.dart';
import 'package:str_gram_beta/search/search_genre_tile.dart';
import 'package:str_gram_beta/searchResult/searchResult_page.dart';

import '../genre/genre_page.dart';

class SearchPage extends ConsumerWidget {
  const SearchPage({super.key});

  static const _horizontal = 20.0;

  void _submitSearch(BuildContext context, SearchModel model, String raw) {
    final query = raw.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchResultPage(query, mainColor)),
    );
    model.searchTextController.clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final model = ref.watch(searchProvider);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(_horizontal, 12, _horizontal, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SearchField(
                        controller: model.searchTextController,
                        onChanged: model.onSearchFieldChanged,
                        onSubmit: (text) => _submitSearch(context, model, text),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'ジャンルから探す',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1C1C1E),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(_horizontal, 0, _horizontal, 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final genre = model.defaultGenresList[index];
                      return SearchGenreTile(
                        genre: genre,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => GenrePage(genre, 'genre')),
                          );
                        },
                      );
                    },
                    childCount: model.defaultGenresList.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    return TextField(
      controller: widget.controller,
      textInputAction: TextInputAction.search,
      autocorrect: false,
      style: const TextStyle(fontSize: 16, color: Color(0xFF1C1C1E)),
      decoration: InputDecoration(
        hintText: '歌詞・曲名・アーティスト',
        hintStyle: const TextStyle(fontSize: 16, color: Color(0xFF8E8E93)),
        filled: true,
        fillColor: const Color(0xFFE5E5EA),
        prefixIcon: const Icon(CupertinoIcons.search, size: 20, color: Color(0xFF8E8E93)),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(CupertinoIcons.clear_circled_solid, size: 18, color: Color(0xFF8E8E93)),
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        isDense: true,
      ),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmit,
    );
  }
}
