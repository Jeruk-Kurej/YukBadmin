import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../pb/state/providers.dart';

/// P1 Masuk.
class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pbCount = ref.watch(nearbyPbProvider).value?.length;
    final area = ref.watch(preferencesProvider).area;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Hero berwarna merah, jadi ikon status bar dibuat terang.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: ClipPath(
                clipper: _SlantClipper(),
                child: ColoredBox(
                  color: YbColors.primary,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(painter: _HeroLines()),
                      ),
                      Positioned.fill(
                        child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 72),
                            child: _HeroContent(pbCount: pbCount, area: area),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        ref.read(sessionProvider.notifier).signInDemo();
                        context.go('/preferensi');
                      },
                      icon: const Icon(Icons.person_outline),
                      label: const Text('Masuk dengan Google'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Dengan masuk, kamu setuju dengan Syarat dan Ketentuan YukBadmin.',
                      textAlign: TextAlign.center,
                      style: YbText.label(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({required this.pbCount, required this.area});

  final int? pbCount;
  final String area;

  @override
  Widget build(BuildContext context) {
    // Isi ditaruh di tengah secara vertikal. Di layar pendek atau teks besar,
    // isi diperkecil supaya tidak terpotong.
    return LayoutBuilder(
      builder: (context, box) => SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: box.maxWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: YbColors.accent,
                    borderRadius: BorderRadius.circular(YbRadius.md),
                  ),
                  child: Icon(
                    Icons.sports_tennis,
                    size: 36,
                    color: YbColors.onAccent,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'YukBadmin',
                  style: YbText.display(size: 46, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Temukan PB badminton yang pas, lalu main lebih rutin.',
                  style: YbText.body(size: 17, color: Colors.white),
                ),
                const SizedBox(height: 16),
                for (final point in const [
                  'Cari komunitas badminton (PB) sesuai level dan jadwalmu',
                  'Kelola member, kehadiran, dan iuran PB-mu',
                  'Bukan untuk booking lapangan',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          point.startsWith('Bukan')
                              ? Icons.do_not_disturb_alt
                              : Icons.check,
                          size: 18,
                          color: YbColors.accent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point,
                            style: YbText.body(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (pbCount != null) ...[
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$pbCount',
                        style: YbText.display(
                          size: 44,
                          color: YbColors.accent,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            'PB aktif di $area',
                            style: YbText.body(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlantClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - 48)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_SlantClipper oldClipper) => false;
}

/// Garis lapangan tipis dan satu garis kuning di sisi kanan hero.
class _HeroLines extends CustomPainter {
  const _HeroLines();

  @override
  void paint(Canvas canvas, Size size) {
    final thin = Paint()
      ..color = Colors.white.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final left = size.width * 0.56;
    canvas.drawRect(
      Rect.fromLTRB(
        left,
        size.height * 0.2,
        size.width + 2,
        size.height * 0.62,
      ),
      thin,
    );
    canvas.drawLine(
      Offset(left, size.height * 0.34),
      Offset(size.width, size.height * 0.34),
      thin,
    );
    canvas.drawLine(
      Offset(left, size.height * 0.46),
      Offset(size.width, size.height * 0.46),
      thin,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 10, 0, 4, size.height * 0.6),
      Paint()..color = YbColors.accent,
    );
  }

  @override
  bool shouldRepaint(_HeroLines oldDelegate) => false;
}
