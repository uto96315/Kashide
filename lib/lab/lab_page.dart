import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';
import 'package:str_gram_beta/lab/lab_feedback.dart';

/// ランキング・アンケートなど試験的なコンテンツを置くタブ。
class LabPage extends StatefulWidget {
  const LabPage({super.key});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  static const _bg = Color(0xFFF4F4F6);
  static const _ink = Color(0xFF0F1419);
  static const _sub = Color(0xFF536471);
  static const _horizontal = 20.0;
  static const _viewportFraction = 0.84;

  final _pageController = PageController(viewportFraction: _viewportFraction);
  var _page = 0;

  static const _posters = <_LabPoster>[
    _LabPoster(
      title: 'ハッシュタグランキング',
      kicker: '歌詞のタグ',
      imageAsset: 'images/card_jpop.jpg',
    ),
    _LabPoster(
      title: 'アーティストランキング',
      kicker: '盛り上がり',
      imageAsset: 'images/card_rock.jpg',
    ),
    _LabPoster(
      title: '歌手の推し曲',
      kicker: '推し曲',
      imageAsset: 'images/card_love.jpg',
    ),
    _LabPoster(
      title: '季節・テーマのアンケート',
      kicker: 'みんなで投票',
      imageAsset: 'images/card_youth.jpg',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = width * _viewportFraction;
    final imageHeight = (cardWidth * 0.52).clamp(120.0, 168.0);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Stack(
                  children: [
                    Positioned.fill(child: _LabGridBackground()),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: _horizontal),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            _LabHeader(),
                            const SizedBox(height: 6),
                            Text(
                              '試作中の機能。公開前のものが並びます。',
                              style: TextStyle(fontSize: 13, height: 1.45, color: _sub),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: imageHeight + 108,
                              child: PageView.builder(
                                controller: _pageController,
                                itemCount: _posters.length,
                                onPageChanged: (i) => setState(() => _page = i),
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: _ExperimentCard(
                                      poster: _posters[index],
                                      imageHeight: imageHeight,
                                      onTap: () => _showPreparing(context),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_posters.length, (i) {
                                final active = i == _page;
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: active ? 14 : 6,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: active ? mainColor : const Color(0xFFD1D1D6),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                            const Spacer(),
                            _ContactTicket(onTap: () => openLabFeedback(context)),
                            SizedBox(height: 12 + bottomInset),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showPreparing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('準備中です'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _LabPoster {
  const _LabPoster({
    required this.title,
    required this.kicker,
    required this.imageAsset,
  });

  final String title;
  final String kicker;
  final String imageAsset;
}

class _LabGridBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _LabGridPainter());
  }
}

class _LabGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const step = 28.0;
    final paint = Paint()
      ..color = const Color(0xFFE2E2E8)
      ..strokeWidth = 0.6;
    for (var x = 0.0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LabHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: mainColor.withValues(alpha: 0.35), width: 1.5),
          ),
          child: const Icon(CupertinoIcons.lab_flask_solid, size: 24, color: mainColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LAB · 試験場',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: mainColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'ラボ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  height: 1,
                  color: _LabPageState._ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ExperimentCard extends StatelessWidget {
  const _ExperimentCard({
    required this.poster,
    required this.imageHeight,
    required this.onTap,
  });

  final _LabPoster poster;
  final double imageHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(poster.imageAsset, fit: BoxFit.cover),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '試験中',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: mainColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poster.kicker,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: _LabPageState._sub,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    poster.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      letterSpacing: -0.2,
                      color: _LabPageState._ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        '準備中',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _LabPageState._sub),
                      ),
                      const Spacer(),
                      Icon(CupertinoIcons.chevron_right, size: 16, color: _LabPageState._sub),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTicket extends StatelessWidget {
  const _ContactTicket({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E5EA)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '運営に意見を送る',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _LabPageState._ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'お問い合わせ・改善・コラボ',
                        style: TextStyle(fontSize: 12, color: _LabPageState._sub),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.arrow_right, size: 18, color: mainColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
