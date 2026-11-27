import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Satu langkah tur: bagian layar yang disorot dan penjelasan singkatnya.
class TourStep {
  const TourStep({
    required this.targets,
    required this.title,
    required this.body,
    this.location,
    this.extraLabel,
    this.onExtra,
  });

  /// Bagian yang disorot. Yang pertama ada di layar yang dipakai, sisanya
  /// cadangan (misalnya tombol "Buat sesi" kalau belum ada sesi).
  final List<GlobalKey> targets;
  final String title;
  final String body;

  /// Rute yang dibuka sebelum langkah ini, misalnya tab lain.
  final String? location;

  /// Tombol tambahan di langkah ini, misalnya "Daftarkan PB".
  final String? extraLabel;
  final VoidCallback? onExtra;
}

/// Menjalankan tur di atas layar yang sedang tampil. Tur berpindah tab lewat
/// [go] dan memanggil [onClose] saat selesai, dilewati, atau tombol tambahan
/// dipilih.
void startTour(
  BuildContext context, {
  required List<TourStep> steps,
  required void Function(String location) go,
  required VoidCallback onClose,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _TourOverlay(
      steps: steps,
      go: go,
      onClose: () {
        entry.remove();
        onClose();
      },
    ),
  );
  overlay.insert(entry);
}

class _TourOverlay extends StatefulWidget {
  const _TourOverlay({
    required this.steps,
    required this.go,
    required this.onClose,
  });

  final List<TourStep> steps;
  final void Function(String location) go;
  final VoidCallback onClose;

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> {
  var _index = 0;
  Rect? _hole;

  @override
  void initState() {
    super.initState();
    // Pindah tab tidak boleh terjadi saat overlay sedang dibangun.
    WidgetsBinding.instance.addPostFrameCallback((_) => _show(0));
  }

  Future<void> _show(int index) async {
    setState(() {
      _index = index;
      _hole = null;
    });
    final step = widget.steps[index];
    if (step.location != null) widget.go(step.location!);
    // Tunggu tab baru selesai dibangun sebelum mencari tombolnya.
    await WidgetsBinding.instance.endOfFrame;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final target = step.targets
        .map((k) => k.currentContext)
        .whereType<BuildContext>()
        .where((c) => c.mounted)
        .firstOrNull;
    if (target == null || !target.mounted) {
      // Bagian yang disorot tidak ada di layar ini; lanjut saja.
      _next();
      return;
    }
    await Scrollable.ensureVisible(
      target,
      alignment: 0.4,
      duration: const Duration(milliseconds: 250),
    );
    if (!mounted || !target.mounted) return;
    final box = target.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) {
      _next();
      return;
    }
    setState(() => _hole = box.localToGlobal(Offset.zero) & box.size);
  }

  void _next() {
    if (_index + 1 >= widget.steps.length) {
      widget.onClose();
    } else {
      _show(_index + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.steps[_index];
    final last = _index == widget.steps.length - 1;
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final hole = _hole?.inflate(6);
    // Balon diletakkan di sisi yang ruangnya lebih lega.
    final spaceBelow = hole == null
        ? 0.0
        : size.height - padding.bottom - hole.bottom - 24;
    final spaceAbove = hole == null ? 0.0 : hole.top - padding.top - 24;
    final below = spaceBelow >= spaceAbove;
    // Bagian yang disorot terlalu besar: balon menumpang di bawah layar
    // supaya teks dan tombolnya tidak terpotong.
    final cramped = (below ? spaceBelow : spaceAbove) < 180;

    return Stack(
      children: [
        // Menahan ketukan ke layar di bawahnya selama tur berjalan.
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: CustomPaint(painter: _SpotlightPainter(hole)),
          ),
        ),
        if (hole != null)
          Positioned(
            left: 16,
            right: 16,
            top: cramped ? null : (below ? hole.bottom + 12 : null),
            bottom: cramped
                ? padding.bottom + 16
                : (below ? null : size.height - hole.top + 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: cramped
                    ? size.height * 0.5
                    : (below ? spaceBelow : spaceAbove),
              ),
              child: _Bubble(
                step: step,
                number: _index + 1,
                total: widget.steps.length,
                last: last,
                onSkip: widget.onClose,
                onNext: _next,
                onExtra: step.onExtra == null
                    ? null
                    : () {
                        widget.onClose();
                        step.onExtra!();
                      },
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.step,
    required this.number,
    required this.total,
    required this.last,
    required this.onSkip,
    required this.onNext,
    this.onExtra,
  });

  final TourStep step;
  final int number;
  final int total;
  final bool last;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final VoidCallback? onExtra;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbColors.surface,
      elevation: 6,
      borderRadius: BorderRadius.circular(YbRadius.md),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Teks boleh digulir kalau ruangnya sempit; tombol selalu terlihat.
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langkah $number dari $total',
                      style: YbText.label(color: YbColors.primary),
                    ),
                    const SizedBox(height: 2),
                    Text(step.title, style: YbText.display(size: 18)),
                    const SizedBox(height: 4),
                    Text(step.body, style: YbText.body()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              children: [
                if (!last)
                  TextButton(
                    onPressed: onSkip,
                    child: Text(
                      'Lewati',
                      style: YbText.body(
                        color: YbColors.muted,
                        weight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (step.extraLabel != null && onExtra != null)
                  OutlinedButton(
                    onPressed: onExtra,
                    child: Text(step.extraLabel!),
                  ),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                  onPressed: onNext,
                  child: Text(last ? 'Selesai' : 'Lanjut'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Menggelapkan layar kecuali lubang di sekitar bagian yang disorot.
class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter(this.hole);

  final Rect? hole;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final rrect = hole == null
        ? null
        : RRect.fromRectAndRadius(hole!, const Radius.circular(YbRadius.md));
    if (rrect != null) {
      path
        ..addRRect(rrect)
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(
      path,
      Paint()..color = Colors.black.withValues(alpha: 0.62),
    );
    if (rrect != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = YbColors.accent,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.hole != hole;
}

/// Kotak ajakan ikut tur, di Beranda pemain dan dashboard pengurus.
class TourBanner extends StatelessWidget {
  const TourBanner({
    super.key,
    required this.title,
    required this.message,
    required this.onStart,
    required this.onClose,
  });

  final String title;
  final String message;
  final VoidCallback onStart;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 14),
      decoration: BoxDecoration(
        color: YbColors.surface,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: YbColors.accentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.tips_and_updates_outlined,
                  size: 20,
                  color: YbColors.ink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: YbText.body(size: 16, weight: FontWeight.w600),
                ),
              ),
              IconButton(
                tooltip: 'Tutup ajakan tur',
                onPressed: onClose,
                icon: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: YbColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Text(
              message,
              style: YbText.body(size: 14, color: YbColors.muted),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: onStart,
            child: const Text('Mulai tur'),
          ),
        ],
      ),
    );
  }
}
