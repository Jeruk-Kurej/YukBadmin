import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/tour.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/state/providers.dart';
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

/// Kerangka lima tab pengurus: Beranda, Member, Jadwal, Iuran, Profil.
class ManageShell extends StatelessWidget {
  const ManageShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, 'Beranda'),
    (Icons.people_outline, 'Member'),
    (Icons.calendar_today_outlined, 'Jadwal'),
    (Icons.payments_outlined, 'Iuran'),
    (Icons.person_outline, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: YbColors.surface,
          border: Border(top: BorderSide(color: YbColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Row(
              children: [
                for (final (i, tab) in _tabs.indexed)
                  Expanded(
                    child: _Tab(
                      key: i == 3 ? TourKeys.duesTab : null,
                      icon: tab.$1,
                      label: tab.$2,
                      selected: shell.currentIndex == i,
                      onTap: () => shell.goBranch(
                        i,
                        initialLocation: i == shell.currentIndex,
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

class _Tab extends StatelessWidget {
  const _Tab({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? YbColors.primary : YbColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? YbColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: YbText.body(
                size: 11,
                color: color,
                weight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// K4 Dashboard PB.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final user = ref.watch(sessionProvider);
    final pb = state.pb;
    if (pb == null) return const SizedBox.shrink();

    final last = state.lastRecorded;
    final next = state.upcoming(ref.watch(nowProvider)()).firstOrNull;
    final paid = state.paidPercent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ClipPath(
            clipper: _HeroClipper(),
            child: Container(
              color: YbColors.night,
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.viewPaddingOf(context).top + 16,
                20,
                44,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pengurus PB',
                          style: YbText.label(color: YbColors.accent),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pb.name,
                          style: YbText.display(size: 24, color: Colors.white),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                        RoleSwitchButton(
                          label: 'Beralih ke mode pemain',
                          onDark: true,
                          onPressed: () => context.go('/beranda'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    children: [
                      YbAvatar(user?.initials ?? '?', accent: true),
                      const SizedBox(height: 8),
                      IconButton(
                        tooltip: 'Mulai tur pengurus',
                        onPressed: () => startManagerTour(context, ref),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          fixedSize: const Size(44, 44),
                        ),
                        icon: const Icon(
                          Icons.help_outline,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: StatTile(
                        value: '${state.members.length}',
                        label: 'Member',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        value: last == null ? '–' : '${last.attendees.length}',
                        label: last == null
                            ? 'Hadir'
                            : 'Hadir ${last.shortLabel.split(' ').first}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: StatTile(
                        value: paid == null ? '–' : '$paid%',
                        label: 'Iuran lunas',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!ref.watch(managerGuideSeenProvider)) ...[
                  TourBanner(
                    title: 'Baru jadi pengurus?',
                    message: 'Kenalan dengan cara kelola PB dalam 1 menit.',
                    onStart: () => startManagerTour(context, ref),
                    onClose: () =>
                        ref.read(managerGuideSeenProvider.notifier).markSeen(),
                  ),
                  const SizedBox(height: 14),
                ],
                if (state.proofsToCheck > 0) ...[
                  YbCard(
                    highlight: true,
                    onTap: () => context.go('/kelola/iuran'),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: YbColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.proofsToCheck} bukti transfer menunggu dicek',
                                style: YbText.body(
                                  size: 15,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Setujui supaya iurannya tercatat lunas.',
                                style: YbText.label(),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: YbColors.muted),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (state.members.isEmpty)
                  _ImportBanner(onTap: () => context.push('/impor'))
                else if (next != null)
                  YbCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sesi berikutnya', style: YbText.label()),
                        const SizedBox(height: 4),
                        Text(next.title, style: YbText.display(size: 17)),
                        const SizedBox(height: 2),
                        Text(
                          '${formatSessionDate(next.start)} · ${next.timeRange} · ${next.venue}',
                          style: YbText.body(color: YbColors.muted),
                        ),
                        if (next.rsvps.isNotEmpty)
                          Text(rsvpSummary(next), style: YbText.label()),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(44),
                          ),
                          onPressed: () =>
                              context.push('/sesi/${next.id}/kehadiran'),
                          child: const Text('Catat kehadiran'),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 18),
                Text('Menu', style: YbText.display(size: 17)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.people_outline,
                        label: 'Member',
                        onTap: () => context.go('/kelola/member'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.calendar_today_outlined,
                        label: 'Jadwal',
                        onTap: () => context.go('/kelola/jadwal'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.payments_outlined,
                        label: 'Iuran',
                        onTap: () => context.go('/kelola/iuran'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.upload_outlined,
                        label: 'Impor catatan',
                        onTap: () => context.push('/impor'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Pengurus',
                        onTap: () => context.push('/kelola/pengurus'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MenuButton(
                        icon: Icons.visibility_outlined,
                        label: 'Lihat sebagai member',
                        onTap: () => context.push('/kelola/lihat-member'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "6 ikut · 1 tidak ikut" untuk kartu sesi pengurus.
String rsvpSummary(SessionEvent e) => [
  '${e.goingCount} ikut',
  if (e.notGoingCount > 0) '${e.notGoingCount} tidak ikut',
].join(' · ');

/// "Rabu, 18 November", atau "Hari ini" / "Besok" kalau dekat.
String formatSessionDate(DateTime start, [DateTime? now]) {
  final today = now ?? DateTime.now();
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(start.year, start.month, start.day);
  final diff = b.difference(a).inDays;
  if (diff == 0) return 'Hari ini';
  if (diff == 1) return 'Besok';
  const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${days[start.weekday - 1]}, ${start.day} ${months[start.month - 1]}';
}

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - 24)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_HeroClipper oldClipper) => false;
}

class _ImportBanner extends StatelessWidget {
  const _ImportBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.primary,
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Punya catatan member lama?',
            style: YbText.display(size: 18, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Tempel daftar dari chat atau Sheets. Kami rapikan jadi daftar member, kamu periksa dulu sebelum disimpan.',
            style: YbText.body(size: 13, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: YbColors.accent,
              foregroundColor: YbColors.onAccent,
              minimumSize: const Size.fromHeight(46),
            ),
            onPressed: onTap,
            icon: const Icon(Icons.upload_outlined, size: 20),
            label: const Text('Impor catatan'),
          ),
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: YbColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: YbColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: YbText.body(weight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
