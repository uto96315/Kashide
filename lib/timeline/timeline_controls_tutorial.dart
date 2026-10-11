import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class TimelineControlsTutorial {
  static const _steps = <_TutorialStep>[
    _TutorialStep('曲を自動で再生', 'カードを見ていると、曲が自動で流れます。'),
    _TutorialStep('並び順を変える', '新着順か、いいねが多い順を選べます。'),
    _TutorialStep('見たい投稿を探す', 'ジャンルなどで絞って、投稿を探せます。'),
    _TutorialStep('表示を切り替える', 'カード表示と一覧表示を切り替えられます。'),
  ];

  static String _key(String? uid) =>
      'timeline_controls_tutorial_v1_${uid ?? 'local'}';

  static Future<void> showIfNeeded(
    BuildContext context, {
    required String? uid,
    required List<GlobalKey> targets,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_key(uid)) ?? false) return;
    if (!context.mounted) return;
    if (targets.length != _steps.length) return;

    final rects = <Rect>[];
    for (final target in targets) {
      final renderObject = target.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      rects.add(renderObject.localToGlobal(Offset.zero) & renderObject.size);
    }

    final overlay = Overlay.of(context, rootOverlay: true);
    if (!overlay.mounted) return;
    final overlayRenderObject = overlay.context.findRenderObject();
    if (overlayRenderObject is! RenderBox || !overlayRenderObject.hasSize) {
      return;
    }
    // Read the finite app viewport from the page context. OverlayEntry's own
    // builder can receive loose constraints, so its LayoutBuilder size is not
    // a safe source for the card width.
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
          onFinished: completed.complete,
        ),
      ),
    );
    overlay.insert(entry);
    await completed.future;
    entry.remove();
    entry.dispose();
    await prefs.setBool(_key(uid), true);
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
    required this.onFinished,
  });

  final List<_TutorialStep> steps;
  final List<Rect> targetRects;
  final Size overlaySize;
  final VoidCallback onFinished;

  @override
  State<_TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<_TutorialOverlay> {
  var _step = 0;

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
                  painter: _SpotlightPainter(
                    widget.targetRects[_step].inflate(8),
                  ),
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
                                    onPressed: widget.onFinished,
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
      widget.onFinished();
      return;
    }
    setState(() => _step++);
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
