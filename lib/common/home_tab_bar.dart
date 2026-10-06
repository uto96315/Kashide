import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

/// 4タブ。選択位置へピンクの円がスライドする。
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.queue_music_rounded,
    Icons.person_rounded,
  ];

  static const _circleSize = 48.0;
  static const _barHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEFF3F4))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: _barHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabW = constraints.maxWidth / _icons.length;
              final left = tabW * index + (tabW - _circleSize) / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    left: left,
                    top: (_barHeight - _circleSize) / 2,
                    width: _circleSize,
                    height: _circleSize,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: mainColor,
                        boxShadow: [
                          BoxShadow(
                            color: mainColor.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < _icons.length; i++)
                        Expanded(
                          child: _TabHit(
                            icon: _icons[i],
                            selected: index == i,
                            onTap: () => onChanged(i),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TabHit extends StatelessWidget {
  const _TabHit({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: HomeTabBar._barHeight,
          child: Center(
            child: Icon(
              icon,
              size: 24,
              color: selected ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
        ),
      ),
    );
  }
}
