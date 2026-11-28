import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

/// Logo YukBadmin: kok dengan lima bulu (biru malam, dua biru, dua limau),
/// sama dengan komponen "V5 / Logo" di Figma Final Design V5.
class YbLogoMark extends StatelessWidget {
  const YbLogoMark({super.key, this.width = 40, this.onDark = false});

  final double width;

  /// Versi untuk latar biru malam: bagian gelap jadi putih.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(width, width * 170 / 200),
        painter: _LogoPainter(onDark: onDark, gap: YbColors.bg),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({required this.onDark, required this.gap});

  final bool onDark;
  final Color gap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200);
    canvas.translate(58, 128);
    final night = onDark ? Colors.white : YbPalette.light.night;
    final bandGap = onDark ? YbPalette.light.night : gap;
    final feathers = <(double, double, Color)>[
      (-62, 132, night),
      (-47, 136, onDark ? YbBrand.featherBlueOnDark : YbBrand.featherBlue),
      (
        -32,
        134,
        onDark ? YbBrand.featherBlueLightOnDark : YbBrand.featherBlueLight,
      ),
      (-17, 130, YbBrand.featherLime),
      (-3, 124, YbPalette.light.accent),
    ];
    final edge = Paint()
      ..color = onDark ? YbPalette.light.night : gap
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (final (deg, len, color) in feathers) {
      canvas.save();
      canvas.rotate(deg * math.pi / 180);
      final path = Path()
        ..moveTo(26, -6)
        ..lineTo(len, -12)
        ..quadraticBezierTo(len + 11, 0, len, 12)
        ..lineTo(26, 6)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      canvas.drawPath(path, edge);
      canvas.restore();
    }
    canvas.save();
    canvas.rotate(-32 * math.pi / 180);
    final cork = Paint()..color = night;
    canvas.drawPath(
      Path()
        ..moveTo(-4, -24)
        ..lineTo(24, -20)
        ..lineTo(24, 20)
        ..lineTo(-4, 24)
        ..close(),
      cork,
    );
    canvas.drawArc(
      Rect.fromCircle(center: const Offset(-4, 0), radius: 24),
      math.pi / 2,
      math.pi,
      true,
      cork,
    );
    final band = Paint()..color = bandGap;
    canvas.drawRect(const Rect.fromLTRB(4, -23, 8, 23), band);
    canvas.drawRect(const Rect.fromLTRB(14, -21.5, 18, 21.5), band);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.onDark != onDark || old.gap != gap;
}

/// Logo dengan tulisan "YukBadmin" di sampingnya.
class YbLogo extends StatelessWidget {
  const YbLogo({super.key, this.size = 44, this.onDark = false});

  /// Lebar tanda kok. Tulisan mengikuti ukurannya.
  final double size;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'YukBadmin',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          YbLogoMark(width: size, onDark: onDark),
          const SizedBox(width: 6),
          Text(
            'YukBadmin',
            style: YbText.body(
              size: size * 0.42,
              weight: FontWeight.w800,
              color: onDark ? YbColors.onNight : YbPalette.light.night,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hero biru malam dengan tepi bawah melengkung seperti busur (Beranda dan
/// Akun di Final Design V5). Isinya sudah diberi jarak dari status bar.
class YbArcHero extends StatelessWidget {
  const YbArcHero({
    super.key,
    required this.child,
    this.depth = 34,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 0),
    this.slashes = true,
  });

  final Widget child;

  /// Selisih tinggi antara sisi dan tengah busur.
  final double depth;
  final EdgeInsets padding;

  /// Garis miring limau di kanan bawah.
  final bool slashes;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PhysicalShape(
        clipper: _ArcClipper(depth),
        clipBehavior: Clip.antiAlias,
        color: YbColors.night,
        elevation: 3,
        shadowColor: YbPalette.light.night.withValues(alpha: 0.35),
        child: CustomPaint(
          painter: _CourtPainter(slashes: slashes, bottomInset: depth),
          child: Padding(
            padding: padding.copyWith(
              top: padding.top + top,
              bottom: padding.bottom + depth,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _ArcClipper extends CustomClipper<Path> {
  const _ArcClipper(this.depth);

  final double depth;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - depth)
    ..quadraticBezierTo(
      size.width / 2,
      size.height + depth,
      0,
      size.height - depth,
    )
    ..close();

  @override
  bool shouldReclip(_ArcClipper old) => old.depth != depth;
}

/// Garis lapangan samar dan garis miring limau sebagai hiasan hero.
class _CourtPainter extends CustomPainter {
  const _CourtPainter({required this.slashes, required this.bottomInset});

  final bool slashes;
  final double bottomInset;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [YbBrand.nightGlow.withValues(alpha: 0.55), Colors.transparent],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, glow);

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final w = size.width;
    final h = size.height;
    // Garis lapangan dalam perspektif, dari kanan bawah.
    canvas.drawLine(Offset(w * 0.45, h), Offset(w * 0.62, h * 0.35), line);
    canvas.drawLine(Offset(w * 1.05, h), Offset(w * 0.88, h * 0.35), line);
    canvas.drawLine(Offset(w * 0.58, h * 0.5), Offset(w * 0.98, h * 0.5), line);
    canvas.drawLine(Offset(w * 0.75, h), Offset(w * 0.75, h * 0.35), line);

    if (!slashes) return;
    // Dua garis miring limau di pojok kanan atas, jauh dari tombol dan teks.
    final lime = Paint()..color = YbPalette.light.accent;
    final top = h * 0.1;
    canvas.drawPath(
      Path()
        ..moveTo(w - 30, top)
        ..lineTo(w, top)
        ..lineTo(w - 60, top + 64)
        ..lineTo(w - 90, top + 64)
        ..close(),
      lime,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w, top + 30)
        ..lineTo(w, top + 52)
        ..lineTo(w - 34, top + 94)
        ..lineTo(w - 56, top + 94)
        ..close(),
      lime..color = lime.color.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(_CourtPainter old) =>
      old.slashes != slashes || old.bottomInset != bottomInset;
}

/// Kepala halaman biru malam dengan lembar terang melengkung di bawahnya
/// (Cari PB dan Perlengkapan di Final Design V5).
class YbSheetHeader extends StatelessWidget {
  const YbSheetHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  static const radius = 28.0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: YbColors.night,
        child: CustomPaint(
          painter: const _CourtPainter(slashes: false, bottomInset: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: padding.copyWith(top: padding.top + top),
                child: child,
              ),
              Container(
                height: radius,
                decoration: BoxDecoration(
                  color: YbColors.bg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(radius),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tombol ikon bulat transparan di atas latar biru malam.
class YbNightIconButton extends StatelessWidget {
  const YbNightIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    style: IconButton.styleFrom(
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      fixedSize: const Size(44, 44),
    ),
    icon: Icon(icon, size: 22, color: YbColors.onNight),
  );
}

/// Chip pintasan biru di tepi busur hero (Main malam, Akhir pekan, Pemula).
class YbHeroChip extends StatelessWidget {
  const YbHeroChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: YbBrand.nightRaised,
        elevation: 4,
        shadowColor: YbPalette.light.night.withValues(alpha: 0.5),
        shape: StadiumBorder(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: YbColors.accent),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: YbText.body(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
