import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../app/tours.dart';
import '../../../core/widgets/tour.dart' show TourBanner;
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart' show dayNames;
import '../data/manage_models.dart';
import '../state/manage_providers.dart';

/// Kerangka lima tab pengurus: Beranda, Member, Jadwal, Iuran, Akun.
class ManageShell extends StatelessWidget {
  const ManageShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    (Icons.people_outline, Icons.people, 'Member'),
    (Icons.calendar_today_outlined, Icons.calendar_today, 'Jadwal'),
    (
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      'Iuran',
    ),
    (Icons.person_outline, Icons.person, 'Akun'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: YbTabBar(
        tabs: _tabs,
        currentIndex: shell.currentIndex,
        itemKeys: {3: TourKeys.duesTab},
        onTap: (i) =>
            shell.goBranch(i, initialLocation: i == shell.currentIndex),
      ),
    );
  }
}

/// K4 Dashboard PB (Final Design v4): hero biru tua dengan angka ringkas,
/// kartu sesi berikutnya dengan titik konfirmasi, lalu menu Kelola PB.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final pb = state.pb;
    if (pb == null) return const SizedBox.shrink();
    final now = ref.watch(nowProvider)();

    final last = state.lastRecorded;
    final next = state.upcoming(now).firstOrNull;
    final paid = state.paidPercent;
    final unpaidMembers = {
      for (final e in state.events)
        for (final d in e.dues.entries)
          if (!d.value.paid && d.value.billable) d.key,
    }.length;
    final weekly = pb.sessions.length;
    final sys = state.duesSystem;
    final refundsToHandle = state.refundsToHandle;
    final lastPlayed = state.past(now).firstOrNull;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            color: YbColors.night,
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.viewPaddingOf(context).top + 12,
              16,
              72,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        pb.name,
                        style: YbText.display(
                          size: 32,
                          color: YbColors.onNight,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Mulai tur pengurus',
                      onPressed: () => startManagerTour(context, ref),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        fixedSize: const Size(44, 44),
                      ),
                      icon: const Icon(
                        Icons.help_outline,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: YbColors.surface,
                    borderRadius: BorderRadius.circular(YbRadius.md),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        _Stat('${state.members.length}', 'Member'),
                        VerticalDivider(width: 1, color: YbColors.line),
                        _Stat(
                          last == null ? '–' : '${last.attendees.length}',
                          last == null
                              ? 'Hadir'
                              : 'Hadir ${dayNames[last.start.weekday]}',
                        ),
                        VerticalDivider(width: 1, color: YbColors.line),
                        _Stat(paid == null ? '–' : '$paid%', 'Iuran lunas'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!ref.watch(managerGuideSeenProvider)) ...[
                    TourBanner(
                      title: 'Baru jadi pengurus?',
                      message: 'Tur singkat: tambah member, catat kehadiran, dan tandai iuran.',
                      onStart: () => startManagerTour(context, ref),
                      onClose: () => ref
                          .read(managerGuideSeenProvider.notifier)
                          .markSeen(),
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (state.members.isEmpty)
                    _ImportBanner(onTap: () => context.push('/impor'))
                  else if (next != null)
                    _NextSessionCard(event: next, members: state.members.length)
                  else
                    YbEmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'Belum ada sesi mendatang',
                      message: 'Buat sesi supaya member bisa konfirmasi ikut.',
                      actionLabel: 'Buka jadwal',
                      onAction: () => context.go('/kelola/jadwal'),
                    ),
                  if (state.proofsToCheck > 0) ...[
                    const SizedBox(height: 14),
                    _Alert(
                      icon: Icons.receipt_long_outlined,
                      title: '${state.proofsToCheck} bukti transfer menunggu',
                      message: 'Periksa supaya iurannya tercatat lunas.',
                      onTap: () => context.go('/kelola/iuran'),
                    ),
                  ],
                  const SizedBox(height: 24),
                  YbSectionTitle('Kelola PB'),
                  const SizedBox(height: 10),
                  YbGroup(
                    children: [
                      YbListRow(
                        icon: Icons.people_outline,
                        title: 'Member',
                        subtitle: '${state.members.length} member',
                        onTap: () => context.go('/kelola/member'),
                      ),
                      YbListRow(
                        icon: Icons.calendar_today_outlined,
                        title: 'Jadwal',
                        subtitle: '$weekly sesi tiap minggu',
                        onTap: () => context.go('/kelola/jadwal'),
                      ),
                      YbListRow(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Iuran',
                        subtitle: unpaidMembers == 0
                            ? 'Semua sudah lunas'
                            : '$unpaidMembers orang belum lunas',
                        onTap: () => context.go('/kelola/iuran'),
                      ),
                      YbListRow(
                        icon: Icons.content_paste_outlined,
                        title: 'Impor catatan',
                        subtitle: 'Salin daftar dari chat atau Sheets',
                        onTap: () => context.push('/impor'),
                      ),
                      YbListRow(
                        icon: Icons.groups_outlined,
                        title: 'Pengurus PB',
                        subtitle: state.coManagers.isEmpty
                            ? 'Baru kamu sendiri'
                            : 'Kamu dan ${state.coManagers.length} pengurus lain',
                        onTap: () => context.push('/kelola/pengurus'),
                      ),
                      YbListRow(
                        icon: Icons.tune,
                        title: 'Sistem iuran',
                        subtitle: sys.summary(pb.feePerSession),
                        onTap: () => context.push('/kelola/sistem-iuran'),
                      ),
                      YbListRow(
                        icon: Icons.undo_rounded,
                        title: 'Pembatalan',
                        subtitle: refundsToHandle == 0
                            ? 'Tidak ada yang perlu diurus'
                            : '$refundsToHandle perlu diurus',
                        trailing: refundsToHandle == 0
                            ? null
                            : YbTag(
                                '$refundsToHandle',
                                tone: YbTagTone.warning,
                              ),
                        chevron: true,
                        onTap: () => context.push('/kelola/pembatalan'),
                      ),
                      if (sys.timing == DuesTiming.perOrang &&
                          lastPlayed != null)
                        YbListRow(
                          icon: Icons.sports_tennis,
                          title: 'Catat pemakaian',
                          subtitle:
                              'Match dan kok sesi ${formatSessionDate(lastPlayed.start, now)}',
                          onTap: () =>
                              context.push('/sesi/${lastPlayed.id}/pemakaian'),
                        ),
                      YbListRow(
                        icon: Icons.visibility_outlined,
                        title: 'Lihat sebagai member',
                        subtitle: 'Coba tampilan member PB-mu',
                        onTap: () => context.push('/kelola/lihat-member'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.value, this.label);

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: YbText.display(size: 24)),
          ),
          Text(
            label,
            style: YbText.body(size: 13, color: YbColors.muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Kartu sesi berikutnya: titik per member (ikut, tidak ikut, belum jawab).
class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({required this.event, required this.members});

  final SessionEvent event;
  final int members;

  @override
  Widget build(BuildContext context) {
    final going = event.goingCount;
    final notGoing = event.notGoingCount;
    final unanswered = (members - going - notGoing).clamp(0, 999);
    final dots = (going + notGoing + unanswered).clamp(0, 36);

    Widget dot(int i) {
      final (fill, border) = i < going
          ? (YbColors.success, YbColors.success)
          : i < going + notGoing
          ? (YbColors.control, YbColors.control)
          : (Colors.transparent, YbColors.line);
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: border, width: 1.5),
        ),
      );
    }

    Widget legend(Color c, String text, {bool hollow = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: hollow ? Colors.transparent : c,
            shape: BoxShape.circle,
            border: Border.all(color: c, width: 1.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(text, style: YbText.body(size: 13, color: YbColors.muted)),
      ],
    );

    return YbCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${formatSessionDate(event.start)} · ${SessionEvent.hmOf(event.start)}',
            style: YbText.display(size: 20),
          ),
          const SizedBox(height: 14),
          Semantics(
            label: '$going ikut, $notGoing tidak ikut, $unanswered belum jawab',
            excludeSemantics: true,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (var i = 0; i < dots; i++) dot(i)],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              legend(YbColors.success, '$going ikut'),
              legend(YbColors.control, '$notGoing tidak ikut'),
              legend(YbColors.line, '$unanswered belum jawab', hollow: true),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/sesi/${event.id}/kehadiran'),
            child: const Text('Catat kehadiran'),
          ),
        ],
      ),
    );
  }
}

class _Alert extends StatelessWidget {
  const _Alert({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: YbColors.warningSoft,
      borderRadius: BorderRadius.circular(YbRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(YbRadius.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: YbColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: YbColors.warning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: YbText.body(size: 16, weight: FontWeight.w600),
                    ),
                    Text(
                      message,
                      style: YbText.body(size: 13, color: YbColors.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: YbColors.ink),
            ],
          ),
        ),
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

class _ImportBanner extends StatelessWidget {
  const _ImportBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.surface,
        borderRadius: BorderRadius.circular(YbRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Punya catatan member lama?', style: YbText.display(size: 20)),
          const SizedBox(height: 6),
          Text(
            'Tempel daftar dari chat atau Sheets. Kami rapikan jadi daftar member, kamu periksa dulu sebelum disimpan.',
            style: YbText.body(size: 14, color: YbColors.muted),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.upload_outlined, size: 20),
            label: const Text('Impor catatan'),
          ),
        ],
      ),
    );
  }
}
