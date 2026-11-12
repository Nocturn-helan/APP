import 'package:flutter/material.dart';

/// 原型启动页的黑色蝴蝶结 Logo，用 CustomPainter 按 SVG 路径 1:1 绘制。
class BowLogo extends StatelessWidget {
  const BowLogo({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 96 / 150,
      child: const CustomPaint(painter: _BowPainter(), isComplex: true),
    );
  }
}

class _BowPainter extends CustomPainter {
  const _BowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // SVG viewBox 是 150 × 96，按实际宽度等比缩放
    final double scale = size.width / 150;
    canvas.save();
    canvas.scale(scale);

    final Paint stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF241E2C);

    final Path left = Path()
      ..moveTo(38, 25)
      ..cubicTo(28, 24, 25, 30, 25, 38)
      ..lineTo(25, 62)
      ..cubicTo(25, 72, 29, 77, 39, 77)
      ..lineTo(74, 58)
      ..lineTo(74, 42)
      ..close();

    final Path right = Path()
      ..moveTo(112, 25)
      ..cubicTo(122, 24, 125, 30, 125, 38)
      ..lineTo(125, 62)
      ..cubicTo(125, 72, 121, 77, 111, 77)
      ..lineTo(76, 58)
      ..lineTo(76, 42)
      ..close();

    canvas.drawPath(left, stroke);
    canvas.drawPath(right, stroke);

    final Paint fill = Paint()..color = const Color(0xFF241E2C);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(67.5, 35, 15, 28),
        const Radius.circular(4),
      ),
      fill,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
