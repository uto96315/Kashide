import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

/// 5スロット（中央は投稿）。選択インジケータの円は4タブのみスライドする。
class HomeTabBar extends StatelessWidget {
  const HomeTabBar({
    super.key,
    required this.index,
    required this.onChanged,
    required this.onPost,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final VoidCallback onPost;

  static const _slotCount = 5;
  static const _postSlot = 2;

  static const _icons = [
    Icons.home_rounded,
    Icons.search_rounded,
    Icons.queue_music_rounded,
    Icons.person_rounded,
  ];

  static const _circleSize = 48.0;
  static const _postSize = 56.0;
  static const _barHeight = 56.0;

  /// タブ index (0..3) → 画面上のスロット (0,1,3,4)。2 は投稿用。
  static int _slotForTab(int tabIndex) => tabIndex < 2 ? tabIndex : tabIndex + 1;

  static int? _tabForSlot(int slot) {
    if (slot == _postSlot) return null;
    return slot < _postSlot ? slot : slot - 1;
  }

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
              final tabW = constraints.maxWidth / _slotCount;
              final slot = _slotForTab(index);
              final left = tabW * slot + (tabW - _circleSize) / 2;
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
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var slot = 0; slot < _slotCount; slot++)
                        Expanded(
                          child: slot == _postSlot
                              ? _CenterPostButton(onTap: onPost)
                              : _TabHit(
                                  icon: _icons[_tabForSlot(slot)!],
                                  selected: index == _tabForSlot(slot),
                                  onTap: () => onChanged(_tabForSlot(slot)!),
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

class _CenterPostButton extends StatelessWidget {
  const _CenterPostButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HomeTabBar._barHeight,
      child: Transform.translate(
        offset: const Offset(0, -4),
        child: Center(
          child: Material(
            color: mainColor,
            elevation: 6,
            shadowColor: mainColor.withValues(alpha: 0.45),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: HomeTabBar._postSize,
                height: HomeTabBar._postSize,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 32),
              ),
            ),
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
