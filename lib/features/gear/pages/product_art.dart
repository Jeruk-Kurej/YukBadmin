import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/gear_models.dart';

/// Gambar sederhana per kategori, dipakai selama produk belum punya foto.
class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.category, this.seed = 0});

  final GearCategory category;
  final int seed;

  static List<Color> get _accents => [
    YbColors.primary,
    Color(0xFF2F5FA8),
    Color(0xFF1F8F6A),
    Color(0xFFD98A2B),
  ];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ColoredBox(
        color: YbColors.isDark ? YbColors.line : const Color(0xFFF3EEEB),
        child: CustomPaint(
          painter: _ArtPainter(category, _accents[seed % _accents.length]),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.category, this.accent);

  final GearCategory category;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = size.center(Offset.zero);
    final ink = Paint()
      ..color = YbColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.025
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = accent;

    switch (category) {
      case GearCategory.raket:
        canvas.save();
        canvas.translate(c.dx, c.dy);
        canvas.rotate(-0.5);
        final head = Rect.fromCenter(
          center: Offset(0, -s * 0.17),
          width: s * 0.3,
          height: s * 0.4,
        );
        canvas.drawOval(head, Paint()..color = Colors.white);
        final strings = Paint()
          ..color = YbColors.line
          ..strokeWidth = s * 0.008;
        for (var i = -2; i <= 2; i++) {
          canvas.drawLine(
            Offset(i * s * 0.05, head.top + s * 0.04),
            Offset(i * s * 0.05, head.bottom - s * 0.04),
            strings,
          );
        }
        canvas.drawOval(head, ink..color = accent);
        canvas.drawLine(
          Offset(0, head.bottom),
          Offset(0, s * 0.3),
          ink..color = YbColors.ink,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(-s * 0.025, s * 0.2, s * 0.05, s * 0.16),
            Radius.circular(s * 0.02),
          ),
          Paint()..color = YbColors.ink,
        );
        canvas.restore();
      case GearCategory.sepatu:
        final w = s * 0.62;
        final left = c.dx - w / 2;
        final base = c.dy + s * 0.12;
        final shoe = Path()
          ..moveTo(left, base)
          ..lineTo(left, base - s * 0.2)
          ..quadraticBezierTo(
            left + w * 0.05,
            base - s * 0.3,
            left + w * 0.3,
            base - s * 0.28,
          )
          ..lineTo(left + w * 0.45, base - s * 0.14)
          ..quadraticBezierTo(left + w * 0.9, base - s * 0.14, left + w, base)
          ..close();
        canvas.drawPath(shoe, Paint()..color = Colors.white);
        canvas.drawPath(shoe, ink);
        canvas.drawRect(
          Rect.fromLTWH(left, base - s * 0.02, w, s * 0.06),
          fill,
        );
        for (var i = 0; i < 3; i++) {
          final x = left + w * (0.22 + i * 0.08);
          canvas.drawLine(
            Offset(x, base - s * 0.24 + i * s * 0.03),
            Offset(x + w * 0.06, base - s * 0.22 + i * s * 0.03),
            ink,
          );
        }
      case GearCategory.senar:
        canvas.drawCircle(
          c,
          s * 0.22,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.07,
        );
        canvas.drawCircle(
          c,
          s * 0.22,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = s * 0.01,
        );
      case GearCategory.grip:
        final roll = Rect.fromCenter(
          center: c,
          width: s * 0.5,
          height: s * 0.26,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(roll, Radius.circular(s * 0.13)),
          Paint()..color = YbColors.ink,
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(roll.right - s * 0.06, c.dy),
            width: s * 0.12,
            height: s * 0.26,
          ),
          fill,
        );
    }
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.category != category || old.accent != accent;
}
