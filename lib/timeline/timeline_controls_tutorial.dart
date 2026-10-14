import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/timeline/swipe_deck_swipe_cue.dart';
import 'package:str_gram_beta/timeline/timeline_view_tutorial_cue.dart';

class TimelineControlsTutorial {
  static const _steps = <_TutorialStep>[
    _TutorialStep(
      'カードをスワイプ',
      '右はいいね、左は次の歌詞へ。下のボタンでも同じ操作ができます。',
    ),
    _TutorialStep('曲を自動で再生', 'カードを見ていると、曲が自動で流れます。'),
    _TutorialStep('並び順を変える', '新着順か、いいねが多い順を選べます。'),
    _TutorialStep('見たい投稿を探す', 'ジャンルなどで絞って、投稿を探せます。'),
    _TutorialStep(
      '表示を切り替える',
      '右上の切替で、スワイプのカードと縦の一覧を行き来できます。',
    ),
  ];

  static const _viewStepIndex = 4;

  static String _key(String? uid) =>
      'timeline_controls_tutorial_v3_${uid ?? 'local'}';

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String? uid,
    required List<GlobalKey> targets,
    SwipeDeckSwipeCue? swipeCue,
    TimelineViewTutorialCue? viewCue,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(uid)) ?? false) return;
    await run(
      context,
      uid: uid,
      targets: targets,
      swipeCue: swipeCue,
      viewCue: viewCue,
      markComplete: true,
    );
  }

  /// マイページなどから再表示（完了済みでも表示する）。
  static Future<bool> run(
    BuildContext context, {
    required String? uid,
    required List<GlobalKey> targets,
    SwipeDeckSwipeCue? swipeCue,
    TimelineViewTutorialCue? viewCue,
    bool markComplete = false,
  }) async {
    if (!context.mounted) return false;
    if (targets.length != _steps.length) return false;

    final rects = <Rect>[];
    for (final target in targets) {
      final renderObject = target.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return false;
      rects.add(renderObject.localToGlobal(Offset.zero) & renderObject.size);
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    if (!overlay.mounted) return false;
    final overlayRenderObject = overlay.context.findRenderObject();
    if (overlayRenderObject is! RenderBox || !overlayRenderObject.hasSize) {
      return false;
    }
    final overlaySize = MediaQuery.sizeOf(context);
    final overlayOrigin = overlayRenderObject.localToGlobal(Offset.zero);
    final overlayRects = rects
        .map((rect) => rect.shift(-overlayOrigin))
        .toList(growable: false);
    final completed = Completer<void>();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: _TutorialOverlay(
          steps: _steps,
          targetRects: overlayRects,
          overlaySize: overlaySize,
          swipeCue: swipeCue,
          viewCue: viewCue,
          onFinished: completed.complete,
        ),
      ),
    );
    overlay.insert(entry);
    await completed.future;
    entry.remove();
    entry.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      swipeCue?.reset();
      viewCue?.reset();
    });
    if (markComplete) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key(uid), true);
    }
    return true;
  }
}

class _TutorialStep {
  const _TutorialStep(this.title, this.description);

  final String title;
  final String description;
}

class _TutorialOverlay extends StatefulWidget {
  const _TutorialOverlay({
    required this.steps,
    required this.targetRects,
    required this.overlaySize,
    required this.swipeCue,
    required this.viewCue,
    required this.onFinished,
  });

  final List<_TutorialStep> steps;
  final List<Rect> targetRects;
  final Size overlaySize;
  final SwipeDeckSwipeCue? swipeCue;
  final TimelineViewTutorialCue? viewCue;
  final VoidCallback onFinished;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _swipeDemo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _viewDemo = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  var _step = 0;

  @override
  void initState() {
    super.initState();
    _swipeDemo.addListener(_syncSwipeCue);
    _viewDemo.addListener(_syncViewCue);
    _applyStepAnimations();
  }

  @override
  void dispose() {
    _swipeDemo.removeListener(_syncSwipeCue);
    _viewDemo.removeListener(_syncViewCue);
    _swipeDemo.dispose();
    _viewDemo.dispose();
    widget.swipeCue?.reset(notify: false);
    widget.viewCue?.reset(notify: false);
    super.dispose();
  }

  void _applyStepAnimations() {
    _swipeDemo.stop();
    _viewDemo.stop();
    widget.swipeCue?.reset(notify: false);
    widget.viewCue?.reset(notify: false);
    if (_step == 0 && widget.swipeCue != null) {
      _swipeDemo
        ..reset()
        ..repeat();
    } else if (_step == TimelineControlsTutorial._viewStepIndex &&
        widget.viewCue != null) {
      _viewDemo
        ..reset()
        ..repeat();
    } else {
      if (widget.swipeCue != null) {
        _swipeDemo.forward(from: 0);
      }
      if (widget.viewCue != null) {
        _viewDemo.forward(from: 0);
      }
    }
  }

  void _syncSwipeCue() {
    if (widget.swipeCue == null || _step != 0) return;
    widget.swipeCue!.dragDx = _tutorialDragOffset(_swipeDemo.value);
  }

  void _syncViewCue() {
    if (widget.viewCue == null || _step != TimelineControlsTutorial._viewStepIndex) {
      return;
    }
    widget.viewCue!.previewDeck(_tutorialDeckPreview(_viewDemo.value));
  }

  /// カード → 一覧 → カード（1周期の末尾は常にカード）。
  static bool _tutorialDeckPreview(double t) {
    if (t < 0.36) return true;
    if (t < 0.58) return false;
    return true;
  }

  void _endTutorialOnCardMode() {
    widget.viewCue?.previewDeck(true);
    widget.viewCue?.reset();
  }

  Rect _spotlightRect() {
    final base = widget.targetRects[_step].inflate(8);
    if (_step != TimelineControlsTutorial._viewStepIndex) return base;
    final toggle = widget.targetRects[TimelineControlsTutorial._viewStepIndex];
    final top = toggle.top - 4;
    final bottom = widget.overlaySize.height - 200;
    return Rect.fromLTRB(12, top, widget.overlaySize.width - 12, bottom);
  }

  /// 右→戻る→左→戻る のデモ（実カードに反映）。
  static double _tutorialDragOffset(double t) {
    if (t < 0.2) {
      return Curves.easeOut.transform(t / 0.2) * 92;
    }
    if (t < 0.3) {
      return 92 * (1 - Curves.easeIn.transform((t - 0.2) / 0.1));
    }
    if (t < 0.55) {
      return -Curves.easeOut.transform((t - 0.3) / 0.25) * 92;
    }
    if (t < 0.65) {
      return -92 * (1 - Curves.easeIn.transform((t - 0.55) / 0.1));
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = widget.overlaySize;
    final cardWidth = (screenSize.width - 36).clamp(0.0, 340.0).toDouble();
    return Material(
      color: Colors.transparent,
      child: SizedBox.fromSize(
        size: screenSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: AbsorbPointer(
                child: CustomPaint(
                  painter: _SpotlightPainter(_spotlightRect()),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: SizedBox(
                    width: cardWidth,
                    child: Material(
                      color: Colors.white,
                      elevation: 12,
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_step + 1} / ${widget.steps.length}',
                              style: const TextStyle(
                                color: mainColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.steps[_step].title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.steps[_step].description,
                              style: const TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Color(0xFF3A3A3C),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: cardWidth - 40,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      _endTutorialOnCardMode();
                                      widget.onFinished();
                                    },
                                    child: const Text('スキップ'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: mainColor,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 48),
                                    ),
                                    onPressed: _next,
                                    child: Text(
                                      _step == widget.steps.length - 1
                                          ? 'はじめる'
                                          : '次へ',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _next() {
    if (_step == widget.steps.length - 1) {
      _endTutorialOnCardMode();
      widget.onFinished();
      return;
    }
    if (_step == 0) {
      widget.swipeCue?.reset();
    }
    if (_step == TimelineControlsTutorial._viewStepIndex) {
      _endTutorialOnCardMode();
    }
    setState(() => _step++);
    _applyStepAnimations();
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter(this.rect);

  final Rect rect;

  @override
  void paint(Canvas canvas, Size size) {
    final fullScreen = Path()..addRect(Offset.zero & size);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(18)));
    final dimmedArea = Path.combine(PathOperation.difference, fullScreen, hole);
    canvas.drawPath(
      dimmedArea,
      Paint()..color = Colors.black.withValues(alpha: 0.72),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(18)),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) => rect != oldDelegate.rect;
}
