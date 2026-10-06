import 'package:flutter/material.dart';
import 'package:str_gram_beta/common/ThemeColor.dart';

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  var _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return AnimatedScale(
      scale: _down && enabled ? 0.97 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: Color(0x66FF749E),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: enabled ? mainColor : const Color(0xFFE4E4E8),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? widget.onPressed : null,
            onHighlightChanged: (down) {
              if (_down == down) return;
              setState(() => _down = down);
            },
            splashColor: Colors.white24,
            highlightColor: Colors.white10,
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: Center(
                child: widget.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                          color: enabled ? Colors.white : const Color(0xFF6C6C70),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
