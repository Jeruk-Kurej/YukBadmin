import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/tours.dart';
import '../../core/widgets/tour.dart' show TourBanner;
import '../../core/widgets/yb_widgets.dart';
import '../auth/preferences_page.dart' show areaOptions;
import '../club/pages/session_ticket.dart';
import '../manage/state/manage_providers.dart' show nowProvider;
import '../club/state/club_providers.dart';
import '../pb/pages/pb_card.dart';
import '../pb/state/providers.dart';

/// P3 Beranda: sapaan, angka papan skor, tiket semua jadwal PB-ku, lalu PB
/// dekat kamu.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(sessionProvider);
    final prefs = ref.watch(preferencesProvider);
    final nearby = ref.watch(nearbyPbProvider);
    final isMember = ref.watch(membershipProvider).isNotEmpty;
    final tourSeen = ref.watch(playerTourSeenProvider);

    final memberships = ref.watch(membershipProvider);
    final tickets = ref.watch(upcomingTicketsProvider);
    final now = ref.watch(nowProvider)();
    final weekEnd = now.add(const Duration(days: 7));
    final thisWeek = tickets.where((t) => t.event.start.isBefore(weekEnd));
    final playedThisMonth = [
      for (final m in memberships)
        for (final e in m.events)
          if (e.start.year == now.year &&
              e.start.month == now.month &&
              !e.start.isAfter(now) &&
              e.attendees.contains(m.memberId))
            e,
    ].length;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          _Greeting(
            name: user?.firstName ?? 'pemain',
            member: isMember,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _AreaPill(area: prefs.area),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: 'Buka akun',
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => context.go('/akun'),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: YbColors.night,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        user?.initials ?? '?',
                        style: YbText.body(
                          size: 14,
                          weight: FontWeight.w800,
                          color: YbColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!tourSeen) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TourBanner(
                title: 'Baru di YukBadmin?',
                message: 'Ikuti tur singkat: cari PB, saring, dan cara gabung.',
                onStart: () => startPlayerTour(context, ref),
                onClose: () =>
                    ref.read(playerTourSeenProvider.notifier).markSeen(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (isMember) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ScoreStrip(
                items: [
                  ('${thisWeek.length}', 'sesi minggu ini'),
                  ('${memberships.length}', 'PB-ku'),
                  ('$playedThisMonth×', 'main bulan ini'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: YbSectionTitle(
                'Jadwalmu',
                action: 'PB-ku',
                onAction: () => context.push('/pb-ku'),
              ),
            ),
            const SizedBox(height: 10),
            const ScheduleRail(),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _FirstPbCard(key: TourKeys.homeSearch, area: prefs.area),
            ),
          const SizedBox(height: 24),
          Padding(
            key: isMember ? TourKeys.homeSearch : null,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: YbSectionTitle(
              'PB dekat kamu',
              action: 'Lihat semua',
              onAction: () => context.go('/cari'),
            ),
          ),
          const SizedBox(height: 10),
          nearby.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: YbEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Daftar PB gagal dimuat',
                message: 'Tutup lalu buka lagi aplikasinya.',
              ),
            ),
            data: (list) => list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: YbEmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'Belum ada PB di ${prefs.area}',
                      message: 'Coba pilih area lain dari tombol area di atas.',
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, pb) in list.indexed) ...[
                            if (i > 0) const SizedBox(width: 12),
                            PbTallCard(pb: pb),
                          ],
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Tombol area di kanan judul. Mengganti area langsung menyaring PB.
class _AreaPill extends ConsumerWidget {
  const _AreaPill({required this.area});

  final String area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Area: $area. Ganti area',
      excludeSemantics: true,
      child: Material(
        color: YbColors.surface,
        shape: StadiumBorder(side: BorderSide(color: YbColors.line)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _pickArea(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, maxWidth: 170),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.place_outlined, size: 18, color: YbColors.ink),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      area,
                      style: YbText.body(size: 14, weight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.expand_more, size: 18, color: YbColors.ink),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _pickArea(BuildContext context, WidgetRef ref) async {
  final current = ref.read(preferencesProvider);
  final picked = await showModalBottomSheet<String>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pilih area', style: YbText.display(size: 20)),
            const SizedBox(height: 12),
            for (final a in areaOptions)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: Text(a, style: YbText.body(size: 16)),
                trailing: a == current.area
                    ? Icon(Icons.check_rounded, color: YbColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(a),
              ),
          ],
        ),
      ),
    ),
  );
  if (picked != null) {
    ref.read(preferencesProvider.notifier).save(current.copyWith(area: picked));
  }
}

/// P3c Beranda pemain baru: ajak memilih area lalu mencari PB.
class _FirstPbCard extends ConsumerWidget {
  const _FirstPbCard({super.key, required this.area});

  final String area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: YbColors.night,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Biasanya kamu main di area mana?',
            style: YbText.display(size: 24, color: YbColors.onNight),
          ),
          const SizedBox(height: 16),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(YbRadius.md),
            child: InkWell(
              borderRadius: BorderRadius.circular(YbRadius.md),
              onTap: () => _pickArea(context, ref),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.place_outlined, color: Color(0xFF192533)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        area,
                        style: YbText.body(
                          size: 16,
                          color: const Color(0xFF192533),
                        ),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: Color(0xFF192533)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: YbColors.accent,
              foregroundColor: YbColors.onAccent,
            ),
            onPressed: () => context.go('/cari'),
            child: const Text('Cari PB'),
          ),
        ],
      ),
    );
  }
}

/// Sapaan di atas Beranda dengan garis lapangan samar di pojok.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.member,
    required this.trailing,
  });

  final String name;
  final bool member;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final title = YbText.display(size: 32);
    return Stack(
      children: [
        Positioned(
          right: -40,
          top: -12,
          width: 230,
          height: 130,
          child: ExcludeSemantics(
            child: CustomPaint(painter: _HeaderCourt(YbColors.ink)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Halo, $name',
                      style: YbText.body(
                        size: 15,
                        weight: FontWeight.w500,
                        color: YbColors.muted,
                      ),
                    ),
                  ),
                  trailing,
                ],
              ),
              const SizedBox(height: 6),
              Semantics(
                header: true,
                child: member
                    ? Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Siap '),
                            TextSpan(
                              text: 'smash',
                              style: title.copyWith(
                                fontStyle: FontStyle.italic,
                                color: YbColors.primary,
                              ),
                            ),
                            const TextSpan(text: ' minggu ini?'),
                          ],
                        ),
                        style: title,
                      )
                    : Text('Yuk cari PB pertamamu', style: title),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Strip angka papan skor: angka miring tebal, label kecil di bawahnya.
class _ScoreStrip extends StatelessWidget {
  const _ScoreStrip({required this.items});

  final List<(String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: YbColors.surface,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (final (i, (value, label)) in items.indexed) ...[
              if (i > 0) VerticalDivider(width: 1, color: YbColors.line),
              Expanded(
                child: Semantics(
                  label: '$value $label',
                  excludeSemantics: true,
                  child: Column(
                    children: [
                      Text(
                        value,
                        style: YbText.score(
                          size: 24,
                          color: i == 0 ? YbColors.primary : YbColors.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: YbText.body(
                          size: 12,
                          weight: FontWeight.w600,
                          color: YbColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Garis lapangan tipis sebagai hiasan sapaan.
class _HeaderCourt extends CustomPainter {
  const _HeaderCourt(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = Offset.zero & size;
    canvas.drawRect(r.deflate(2), p);
    final cx = r.center.dx;
    for (final x in [cx, cx - r.width * 0.18, cx + r.width * 0.18]) {
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), p);
    }
    for (final y in [r.top + 14, r.bottom - 14]) {
      canvas.drawLine(Offset(r.left, y), Offset(r.right, y), p);
    }
  }

  @override
  bool shouldRepaint(_HeaderCourt oldDelegate) => oldDelegate.color != color;
}
