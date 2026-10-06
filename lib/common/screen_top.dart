import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.only(left: 6, right: 8),
      minimumSize: const Size(44, 44),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
      child: const Icon(CupertinoIcons.back, size: 26, color: Color(0xFF1C1C1E)),
    );
  }
}

class ScreenTop extends StatelessWidget {
  const ScreenTop({
    super.key,
    this.title,
    this.trailing,
    this.showBack,
  });

  final String? title;
  final Widget? trailing;
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final back = showBack ?? Navigator.canPop(context);
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 56),
                child: Text(
                  title!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
            Row(
              children: [
                if (back) const AppBackButton() else const SizedBox(width: 16),
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
