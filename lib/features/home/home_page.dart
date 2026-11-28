import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../app/tours.dart';
import '../../core/widgets/tour.dart' show TourBanner;
import '../../core/widgets/yb_brand.dart';
import '../../core/widgets/yb_widgets.dart';
import '../auth/preferences_page.dart' show areaOptions;
import '../club/pages/session_ticket.dart';
import '../manage/state/manage_providers.dart' show nowProvider;
import '../club/state/club_providers.dart';
import '../pb/data/pb_models.dart';
import '../pb/pages/pb_card.dart';
import '../pb/state/providers.dart';

/// P3 Beranda (Final Design V5): hero biru berbusur berisi sapaan, pilihan
/// area, dan pintasan filter. Member juga melihat papan skor dan tiket semua
/// jadwal PB-ku. Setelah itu PB dekat kamu.
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

    // Bukan ListView, supaya tiket dan banner tur sudah dibangun dan bisa
    // disorot tur meski berada di bawah hero.
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HomeHero(
            name: user?.firstName ?? 'pemain',
            member: isMember,
            area: prefs.area,
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
            const SizedBox(height: 24),
          ],
          Padding(
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

/// Hero Beranda: logo, sapaan, judul miring, area + Cari PB, dan tiga
/// pintasan filter yang duduk di tepi busur.
class _HomeHero extends ConsumerWidget {
  const _HomeHero({
    required this.name,
    required this.member,
    required this.area,
  });

  final String name;
  final bool member;
  final String area;

  static const _depth = 34.0;

  void _searchWith(BuildContext context, WidgetRef ref, PbFilter filter) {
    ref.read(filterProvider.notifier).set(filter);
    context.go('/cari');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = YbText.hero(size: 34, color: YbColors.onNight);
    final lime = title.copyWith(color: YbColors.accent);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        YbArcHero(
          depth: _depth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const YbLogo(size: 42, onDark: true),
              const SizedBox(height: 18),
              Text(
                'Halo, $name',
                style: YbText.body(
                  size: 15,
                  weight: FontWeight.w500,
                  color: YbColors.onNight.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text.rich(
                  member
                      ? TextSpan(
                          children: [
                            const TextSpan(text: 'Siap '),
                            TextSpan(text: 'smash', style: lime),
                            const TextSpan(text: '\nminggu ini?'),
                          ],
                        )
                      : TextSpan(
                          children: [
                            const TextSpan(text: 'Yuk cari PB\n'),
                            TextSpan(text: 'pertamamu.', style: lime),
                          ],
                        ),
                  style: title,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                member
                    ? 'Mau cari PB lain? Pilih area mainmu.'
                    : 'Biasanya kamu main di area mana?',
                style: YbText.body(
                  size: 14,
                  color: YbColors.onNight.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                key: TourKeys.homeSearch,
                builder: (context, box) {
                  final search = FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: YbColors.accent,
                      foregroundColor: YbColors.onAccent,
                      minimumSize: const Size(0, 52),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      textStyle: YbText.body(size: 16, weight: FontWeight.w700),
                    ),
                    onPressed: () => context.go('/cari'),
                    icon: const Icon(Icons.search, size: 20),
                    label: const Text('Cari PB'),
                  );
                  // Layar sempit atau teks besar: area dan tombol bertumpuk.
                  final narrow =
                      box.maxWidth < 340 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.15;
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AreaField(area: area),
                        const SizedBox(height: 8),
                        search,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: _AreaField(area: area)),
                      const SizedBox(width: 8),
                      search,
                    ],
                  );
                },
              ),
              // Ruang untuk pintasan yang duduk di tepi busur.
              const SizedBox(height: 44),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 6,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                YbHeroChip(
                  icon: Icons.nights_stay_outlined,
                  label: 'Main malam',
                  onTap: () => _searchWith(
                    context,
                    ref,
                    const PbFilter(dayParts: {DayPart.malam}),
                  ),
                ),
                const SizedBox(width: 8),
                YbHeroChip(
                  icon: Icons.calendar_month_outlined,
                  label: 'Akhir pekan',
                  onTap: () => _searchWith(
                    context,
                    ref,
                    const PbFilter(weekendOnly: true),
                  ),
                ),
                const SizedBox(width: 8),
                YbHeroChip(
                  icon: Icons.spa_outlined,
                  label: 'Pemula',
                  onTap: () => _searchWith(
                    context,
                    ref,
                    const PbFilter(levels: {Level.f, Level.e}),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kolom area putih di hero. Mengganti area langsung menyaring PB.
class _AreaField extends ConsumerWidget {
  const _AreaField({required this.area});

  final String area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      label: 'Area: $area. Ganti area',
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _pickArea(context, ref),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 20,
                    color: YbColors.onAccent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      area,
                      style: YbText.body(
                        size: 15,
                        weight: FontWeight.w600,
                        color: YbColors.onAccent,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.expand_more,
                    size: 20,
                    color: YbColors.onAccent,
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
