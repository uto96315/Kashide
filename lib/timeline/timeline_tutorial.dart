import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class TimelineTutorialStorage {
  static const _version = 1;

  static String _key(String? uid) => 'timeline_tutorial_v${_version}_${uid ?? 'local'}';

  static Future<bool> shouldShow(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key(uid)) ?? false);
  }

  static Future<void> markComplete(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}

class TimelineTutorialTargets {
  TimelineTutorialTargets({
    required this.viewToggle,
    required this.autoplay,
    required this.sort,
    required this.filter,
    required this.swipeCard,
    required this.swipeActions,
  });

  final GlobalKey viewToggle;
  final GlobalKey autoplay;
  final GlobalKey sort;
  final GlobalKey filter;
  final GlobalKey swipeCard;
  final GlobalKey swipeActions;

  List<GlobalKey> keysForStep(int step) {
    switch (step) {
      case 0:
        return [viewToggle];
      case 1:
        return [swipeCard, swipeActions];
      case 2:
        return [filter, autoplay, sort];
      default:
        return [];
    }
  }
}

class TimelineTutorialOverlay extends StatefulWidget {
  const TimelineTutorialOverlay({
    super.key,
    required this.step,
    required this.stepCount,
    required this.title,
    required this.body,
    required this.targets,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final int stepCount;
  final String title;
  final String body;
  final TimelineTutorialTargets targets;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<TimelineTutorialOverlay> createState() => _TimelineTutorialOverlayState();
}

class _TimelineTutorialOverlayState extends State<TimelineTutorialOverlay> {
  List<Rect> _holes = [];
  var _remeasureAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
  }

  @override
  void didUpdateWidget(TimelineTutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step != widget.step) {
      _remeasureAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    }
  }

  void _remeasure() {
    if (!mounted) return;
    final keys = widget.targets.keysForStep(widget.step);
    final rects = <Rect>[];
    for (final key in keys) {
      final rect = _globalRect(key);
      if (rect != null) rects.add(rect.inflate(6));
    }
    setState(() => _holes = rects);
    if (rects.isEmpty && _remeasureAttempts < 12) {
      _remeasureAttempts++;
      WidgetsBinding.instance.addPostFrameCallback((_) => _remeasure());
    }
  }

  Rect? _globalRect(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return null;
    final offset = box.localToGlobal(Offset.zero);
    return offset & box.size;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final last = widget.step >= widget.stepCount - 1;
    final holeTop = _holes.isEmpty ? null : _holes.map((r) => r.top).reduce((a, b) => a < b ? a : b);
    final showCardAbove = holeTop != null && holeTop > media.size.height * 0.42;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(holes: _holes),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: showCardAbove ? 72 : null,
            bottom: showCardAbove ? null : 24 + media.padding.bottom,
            child: _TutorialCard(
              step: widget.step,
              stepCount: widget.stepCount,
              title: widget.title,
              body: widget.body,
              last: last,
              onNext: widget.onNext,
              onSkip: widget.onSkip,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.holes});

  final List<Rect> holes;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    for (final hole in holes) {
      dim.addRRect(RRect.fromRectAndRadius(hole, const Radius.circular(14)));
    }
    dim.fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = const Color(0x99000000));
    for (final hole in holes) {
      final rrect = RRect.fromRectAndRadius(hole, const Radius.circular(14));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = mainColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) => oldDelegate.holes != holes;
}

class _TutorialCard extends StatelessWidget {
  const _TutorialCard({
    required this.step,
    required this.stepCount,
    required this.title,
    required this.body,
    required this.last,
    required this.onNext,
    required this.onSkip,
  });

  final int step;
  final int stepCount;
  final String title;
  final String body;
  final bool last;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${step + 1} / $stepCount',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF8E8E93)),
            ),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F1419))),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(fontSize: 15, height: 1.45, color: Color(0xFF536471))),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: onSkip, child: const Text('スキップ')),
                const Spacer(),
                FilledButton(
                  onPressed: onNext,
                  style: FilledButton.styleFrom(backgroundColor: mainColor),
                  child: Text(last ? 'はじめる' : '次へ'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

const timelineTutorialStepCount = 3;

String timelineTutorialTitle(int step) {
  switch (step) {
    case 0:
      return 'カードとタイムライン';
    case 1:
      return 'スワイプとボタン';
    case 2:
      return '絞り込み・再生・並び替え';
    default:
      return '';
  }
}

String timelineTutorialBody(int step) {
  switch (step) {
    case 0:
      return '右上の切り替えで、スワイプのカード表示と一覧のタイムライン表示を変えられます。';
    case 1:
      return '右スワイプ／いいねで保存、左スワイプ／✕はカードに出さない（タイムラインには残ります）。真ん中はプレイリストに追加です。';
    case 2:
      return '絞り込みで条件を指定、音符はカードの自動再生（マナーモードでは鳴りません）、並び替えで表示順を変えられます。';
    default:
      return '';
  }
}
