import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 原型里的渐变主按钮（上传图片 / 下载图片）。
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.radius = 26,
    this.fontSize = 15,
    this.letterSpacing = 0.5,
    this.shadowColor = const Color(0x528C64D2),
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double radius;
  final double fontSize;
  final double letterSpacing;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.55,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            gradient: AppGradients.button,
            borderRadius: BorderRadius.circular(radius),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: shadowColor,
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  letterSpacing: letterSpacing,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
