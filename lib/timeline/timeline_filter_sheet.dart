import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/timeline/timeline_filter.dart';

Future<TimelineFilterState?> showTimelineFilterSheet(
  BuildContext context, {
  required TimelineFilterState initial,
  required Set<String> availableGenres,
  required int loadedPostCount,
}) {
  return showModalBottomSheet<TimelineFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _TimelineFilterSheet(
          initial: initial,
          availableGenres: availableGenres,
          loadedPostCount: loadedPostCount,
        ),
  );
}

class _TimelineFilterSheet extends StatefulWidget {
  const _TimelineFilterSheet({
    required this.initial,
    required this.availableGenres,
    required this.loadedPostCount,
  });

  final TimelineFilterState initial;
  final Set<String> availableGenres;
  final int loadedPostCount;

  @override
  State<_TimelineFilterSheet> createState() => _TimelineFilterSheetState();
}

class _TimelineFilterSheetState extends State<_TimelineFilterSheet> {
  late Set<String> _genres = Set<String>.from(widget.initial.genres);
  late TimelineCommentFilter _comments = widget.initial.commentFilter;
  late TimelineTriFilter _youtube = widget.initial.youtubeFilter;
  late TimelineTriFilter _explanation = widget.initial.explanationFilter;

  TimelineFilterState get _draft => TimelineFilterState(
        genres: _genres,
        commentFilter: _comments,
        youtubeFilter: _youtube,
        explanationFilter: _explanation,
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E5EA), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('絞り込み', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'ジャンルを1つだけ選ぶと、投稿全体から新着順で探します（探すタブと同様）。'
            'コメント有無などを組み合わせる場合は、読み込み済み投稿に追加で絞り込み、'
            '必要に応じて自動で追加読み込みします（現在 ${widget.loadedPostCount} 件読み込み済み）。',
            style: const TextStyle(fontSize: 13, height: 1.35, color: Color(0xFF536471)),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('ジャンル'),
          const SizedBox(height: 8),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final genre in (widget.availableGenres.toList()..sort()))
                  FilterChip(
                    label: Text(genre),
                    selected: _genres.contains(genre),
                    selectedColor: mainColor.withValues(alpha: 0.2),
                    checkmarkColor: mainColor,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _genres.add(genre);
                        } else {
                          _genres.remove(genre);
                        }
                      });
                    },
                  ),
              ],
            ),
          const SizedBox(height: 20),
          const _SectionTitle('コメント'),
          const SizedBox(height: 8),
          _SegmentRow<TimelineCommentFilter>(
            values: TimelineCommentFilter.values,
            selected: _comments,
            label: (v) => switch (v) {
              TimelineCommentFilter.all => 'すべて',
              TimelineCommentFilter.withComments => 'あり',
              TimelineCommentFilter.withoutComments => 'なし',
            },
            onChanged: (v) => setState(() => _comments = v),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('YouTubeリンク'),
          const SizedBox(height: 8),
          _SegmentRow<TimelineTriFilter>(
            values: TimelineTriFilter.values,
            selected: _youtube,
            label: (v) => switch (v) {
              TimelineTriFilter.all => 'すべて',
              TimelineTriFilter.yes => 'あり',
              TimelineTriFilter.no => 'なし',
            },
            onChanged: (v) => setState(() => _youtube = v),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('ひとこと'),
          const SizedBox(height: 8),
          _SegmentRow<TimelineTriFilter>(
            values: TimelineTriFilter.values,
            selected: _explanation,
            label: (v) => switch (v) {
              TimelineTriFilter.all => 'すべて',
              TimelineTriFilter.yes => 'あり',
              TimelineTriFilter.no => 'なし',
            },
            onChanged: (v) => setState(() => _explanation = v),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, TimelineFilterState.empty),
                child: const Text('クリア'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: mainColor,
                  minimumSize: const Size(96, 44),
                ),
                onPressed: () => Navigator.pop(context, _draft),
                child: const Text('適用'),
              ),
            ],
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3A3A3C)));
  }
}

class _SegmentRow<T> extends StatelessWidget {
  const _SegmentRow({
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: const Color(0xFFF2F2F7), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == value ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected == value ? const [BoxShadow(color: Color(0x14000000), blurRadius: 4)] : null,
                  ),
                  child: Text(
                    label(value),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected == value ? FontWeight.w700 : FontWeight.w500,
                      color: selected == value ? mainColor : const Color(0xFF536471),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
