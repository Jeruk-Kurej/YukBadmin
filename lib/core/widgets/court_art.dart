import 'package:flutter/material.dart';

/// Ilustrasi lapangan badminton, dipakai selama PB belum punya foto sendiri.
/// [seed] memilih variasi warna supaya tiap PB terlihat berbeda.
class CourtArt extends StatelessWidget {
  const CourtArt({super.key, required this.seed, this.showLamps = true});

  final int seed;

  /// Matikan saat gambar berada di balik status bar supaya tidak bertabrakan.
  final bool showLamps;

  static const _palettes = [
    [Color(0xFF1F8F6A), Color(0xFF156B50), Color(0xFF22313A)],
    [Color(0xFFD98A2B), Color(0xFFA85F12), Color(0xFF3A2414)],
    [Color(0xFF2F5FA8), Color(0xFF1A3A70), Color(0xFF0D1524)],
    [Color(0xFF7A4CA8), Color(0xFF4F2D75), Color(0xFF1D1330)],
    [Color(0xFFB8323A), Color(0xFF7C1A20), Color(0xFF2A1012)],
    [Color(0xFF2E9AA3), Color(0xFF1B6A72), Color(0xFF10262A)],
  ];

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[seed % _palettes.length];
    return ExcludeSemantics(
      child: CustomPaint(
        painter: _CourtPainter(palette, showLamps),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CourtPainter extends CustomPainter {
  _CourtPainter(this.palette, this.showLamps);

  final List<Color> palette;
  final bool showLamps;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Dinding gedung di bagian atas.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette[2], Color.lerp(palette[2], palette[1], 0.5)!],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Lantai lapangan berbentuk trapesium supaya terasa berperspektif.
    final horizon = h * 0.42;
    final floor = Path()
      ..moveTo(w * 0.12, horizon)
      ..lineTo(w * 0.88, horizon)
      ..lineTo(w * 1.15, h)
      ..lineTo(-w * 0.15, h)
      ..close();
    canvas.drawPath(
      floor,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette[1], palette[0]],
        ).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)),
    );

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w / 160).clamp(1.0, 3.0);

    Offset at(double x, double t) {
      // x: -1..1 dari kiri ke kanan lapangan, t: 0 (jauh) .. 1 (dekat).
      final y = horizon + (h - horizon) * t;
      final halfWidth = w * (0.30 + 0.42 * t);
      return Offset(w / 2 + x * halfWidth, y);
    }

    // Garis tepi, garis tengah, dan garis servis.
    for (final x in [-1.0, -0.86, 0.0, 0.86, 1.0]) {
      canvas.drawLine(at(x, 0.08), at(x, 1), line);
    }
    for (final t in [0.08, 0.38, 0.72]) {
      canvas.drawLine(at(-1, t), at(1, t), line);
    }

    // Net.
    final netLeft = at(-1.05, 0.38);
    final netRight = at(1.05, 0.38);
    final netHeight = h * 0.11;
    canvas.drawRect(
      Rect.fromPoints(netLeft.translate(0, -netHeight), netRight),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );
    canvas.drawLine(
      netLeft.translate(0, -netHeight),
      netRight.translate(0, -netHeight),
      line,
    );

    if (!showLamps) return;

    // Lampu gedung.
    final lamp = Paint()..color = Colors.white.withValues(alpha: 0.75);
    for (var i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(w * (0.2 + 0.2 * i), h * 0.13),
            width: w * 0.09,
            height: h * 0.035,
          ),
          const Radius.circular(2),
        ),
        lamp,
      );
    }
  }

  @override
  bool shouldRepaint(_CourtPainter oldDelegate) =>
      oldDelegate.palette != palette || oldDelegate.showLamps != showLamps;
}
