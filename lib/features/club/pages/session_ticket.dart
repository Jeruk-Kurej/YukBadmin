import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../manage/data/manage_models.dart';
import '../../../core/widgets/yb_widgets.dart' show formatRupiahShort;
import '../../manage/state/manage_providers.dart';
import '../../pb/data/pb_models.dart';
import '../../pb/state/providers.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';

/// Satu sesi dari PB-ku, siap ditampilkan sebagai tiket.
typedef TicketEntry = ({Membership membership, Pb pb, SessionEvent event});

/// Semua sesi mendatang dari semua PB-ku, dari yang paling dekat.
final upcomingTicketsProvider = Provider<List<TicketEntry>>((ref) {
  final memberships = ref.watch(membershipProvider);
  final pbs = ref.watch(pbListProvider).value ?? const <Pb>[];
  final now = ref.watch(nowProvider)();
  final list = <TicketEntry>[
    for (final m in memberships)
      if (pbs.where((p) => p.id == m.pbId).firstOrNull case final pb?)
        for (final e in m.upcoming(now)) (membership: m, pb: pb, event: e),
  ]..sort((a, b) => a.event.start.compareTo(b.event.start));
  return list;
});

/// P3 "Jadwalmu": tiket semua sesi PB-ku yang bisa digeser ke samping.
class ScheduleRail extends ConsumerWidget {
  const ScheduleRail({super.key, this.limit = 8});

  final int limit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(upcomingTicketsProvider).take(limit).toList();
    if (tickets.isEmpty) {
      final first = ref.watch(membershipProvider).firstOrNull;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: YbColors.surface,
            borderRadius: BorderRadius.circular(YbRadius.lg),
          ),
          child: Row(
            children: [
              Icon(Icons.event_busy_outlined, color: YbColors.muted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada sesi terjadwal di PB-mu.',
                  style: YbText.body(color: YbColors.muted),
                ),
              ),
              if (first != null)
                TextButton(
                  onPressed: () => context.push('/pb-ku/${first.pbId}'),
                  child: const Text('Lihat PB-ku'),
                ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
      clipBehavior: Clip.none,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, t) in tickets.indexed) ...[
              if (i > 0) const SizedBox(width: 12),
              SessionTicket(entry: t, width: tickets.length == 1 ? null : 300),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tiket sesi: potongan tanggal limau, garis sobekan, lalu badan biru malam
/// berisi foto PB yang sangat tipis supaya teks tetap mudah dibaca.
class SessionTicket extends ConsumerWidget {
  const SessionTicket({super.key, required this.entry, this.width});

  final TicketEntry entry;

  /// Lebar tetap di deretan; null berarti mengikuti lebar layar.
  final double? width;

  static const _stub = 72.0;
  static const _notch = 16.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:membership, :pb, :event) = entry;
    final memberId = membership.memberId;
    final rsvp = event.rsvps[memberId];
    final due = event.dues[memberId];
    final going = event.goingCount;
    final screen = MediaQuery.sizeOf(context).width;
    final w = width == null ? screen - 32 : width!.clamp(0, screen - 56);
    final shortPb = pb.name.replaceFirst(' Surabaya', '');

    final status = switch (rsvp) {
      null => _IkutButton(
        onPressed: () => ref
            .read(membershipProvider.notifier)
            .setRsvp(pb.id, event.id, Rsvp.ikut),
      ),
      Rsvp.ikut when due != null && !due.paid && due.billable => _StatusChip(
        icon: Icons.account_balance_wallet_outlined,
        text: due.awaitingCheck
            ? 'Bukti dicek'
            : 'Bayar ${formatRupiahShort(due.amount)}',
        warning: !due.awaitingCheck,
      ),
      Rsvp.ikut => const _StatusChip(
        icon: Icons.check_rounded,
        text: 'Kamu ikut',
      ),
      Rsvp.tidak => const _StatusChip(text: 'Tidak ikut', muted: true),
    };

    return Semantics(
      button: true,
      label:
          '${event.title} ${pb.name}, ${dayNames[event.start.weekday]} '
          '${event.start.day} ${monthNames[event.start.month - 1]}, '
          '${event.timeRange}, ${event.venue}. $going ikut.',
      child: SizedBox(
        width: w.toDouble(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(YbRadius.lg),
            onTap: () => context.push('/pb-ku/${pb.id}'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(YbRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: YbColors.night.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(YbRadius.lg),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DateStub(date: event.start, width: _stub),
                          Expanded(
                            child: _TicketBody(
                              pb: pb,
                              kicker: '${event.title} · $shortPb',
                              time: event.timeRange,
                              venue: event.venue,
                              going: going,
                              status: status,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Garis sobekan dan dua lubang di antara potongan dan badan.
                Positioned(
                  left: _stub - 1,
                  top: 10,
                  bottom: 10,
                  child: const ExcludeSemantics(child: _Perforation()),
                ),
                for (final top in [true, false])
                  Positioned(
                    left: _stub - _notch / 2,
                    top: top ? -_notch / 2 : null,
                    bottom: top ? null : -_notch / 2,
                    child: Container(
                      width: _notch,
                      height: _notch,
                      decoration: BoxDecoration(
                        color: YbColors.bg,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateStub extends StatelessWidget {
  const _DateStub({required this.date, required this.width});

  final DateTime date;
  final double width;

  @override
  Widget build(BuildContext context) {
    final label = YbText.body(
      size: 11,
      weight: FontWeight.w800,
      color: YbColors.onAccent,
    ).copyWith(letterSpacing: 1.2);
    return Container(
      width: width,
      color: YbColors.accent,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(dayShort[date.weekday]!.toUpperCase(), style: label),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${date.day}',
              style: YbText.score(size: 34, color: YbColors.onAccent),
            ),
          ),
          Text(
            monthNames[date.month - 1].substring(0, 3).toUpperCase(),
            style: label,
          ),
        ],
      ),
    );
  }
}

class _TicketBody extends StatelessWidget {
  const _TicketBody({
    required this.pb,
    required this.kicker,
    required this.time,
    required this.venue,
    required this.going,
    required this.status,
  });

  final Pb pb;
  final String kicker;
  final String time;
  final String venue;
  final int going;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    final soft = YbColors.onNight.withValues(alpha: 0.78);
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: YbColors.night)),
        // Foto PB sangat tipis; tanpa foto, garis lapangan samar.
        Positioned.fill(
          child: ExcludeSemantics(
            child: Opacity(
              opacity: 0.34,
              child: YbPhoto(
                path: pb.photoPaths.firstOrNull,
                fallback: const CustomPaint(painter: _CourtLines()),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  YbColors.night.withValues(alpha: 0.94),
                  YbColors.night.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                kicker.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YbText.body(
                  size: 11,
                  weight: FontWeight.w700,
                  color: soft,
                ).copyWith(letterSpacing: 0.8),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  time,
                  style: YbText.score(size: 26, color: YbColors.onNight),
                ),
              ),
              Text(
                venue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: YbText.body(size: 13, color: soft),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.groups_rounded, size: 18, color: soft),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          going == 0 ? 'Belum ada' : '$going ikut',
                          style: YbText.body(
                            size: 13,
                            weight: FontWeight.w600,
                            color: YbColors.onNight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  status,
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Satu tombol kecil "Ikut" menggantikan pasangan Ikut/Tidak ikut.
/// Batal ikut dari halaman PB-ku (ketuk tiketnya).
class _IkutButton extends StatelessWidget {
  const _IkutButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: YbColors.accent,
      foregroundColor: YbColors.onAccent,
      minimumSize: const Size(72, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      textStyle: YbText.body(size: 14, weight: FontWeight.w800),
    ),
    onPressed: onPressed,
    child: const Text('Ikut'),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.text,
    this.icon,
    this.warning = false,
    this.muted = false,
  });

  final String text;
  final IconData? icon;
  final bool warning;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final fg = warning
        ? YbColors.night
        : muted
        ? YbColors.onNight.withValues(alpha: 0.7)
        : YbColors.accent;
    final bg = warning
        ? YbColors.accent
        : YbColors.onNight.withValues(alpha: muted ? 0.10 : 0.14);
    return Container(
      constraints: const BoxConstraints(minHeight: 32),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(YbRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: YbText.body(size: 12, weight: FontWeight.w700, color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Garis putus-putus vertikal seperti sobekan tiket.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(2, double.infinity), painter: _Dashes());
}

class _Dashes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = YbColors.night.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (var y = 0.0; y < size.height; y += 8) {
      canvas.drawLine(
        Offset(1, y),
        Offset(1, (y + 4).clamp(0, size.height)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Dashes oldDelegate) => false;
}

/// Garis lapangan badminton putih, cadangan kalau PB belum punya foto.
class _CourtLines extends CustomPainter {
  const _CourtLines();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final r = Rect.fromLTWH(6, 6, size.width - 12, size.height - 12);
    canvas.drawRect(r, p);
    final cx = r.center.dx;
    canvas.drawLine(
      Offset(cx, r.top),
      Offset(cx, r.bottom),
      p..strokeWidth = 2.4,
    );
    p.strokeWidth = 1.4;
    final serviceGap = r.width * 0.16;
    for (final x in [
      cx - serviceGap,
      cx + serviceGap,
      r.left + 10,
      r.right - 10,
    ]) {
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
    }
    for (final y in [r.top + 10, r.bottom - 10]) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), p);
    }
    canvas.drawLine(
      Offset(r.left + 10, r.center.dy),
      Offset(cx - serviceGap, r.center.dy),
      p,
    );
    canvas.drawLine(
      Offset(cx + serviceGap, r.center.dy),
      Offset(r.right - 10, r.center.dy),
      p,
    );
  }

  @override
  bool shouldRepaint(_CourtLines oldDelegate) => false;
}
