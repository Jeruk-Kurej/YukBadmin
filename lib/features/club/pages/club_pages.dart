import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/data/manage_models.dart';
import '../../manage/pages/manage_widgets.dart';
import '../../manage/state/manage_providers.dart';
import '../../pb/data/pb_models.dart';
import '../../pb/state/providers.dart';
import '../data/club_models.dart';
import '../state/club_providers.dart';
import 'club_view.dart';

/// Satu hal terpenting yang perlu dikerjakan member. Kartu hanya
/// menampilkan satu ajakan supaya tidak penuh tag.
({String label, IconData icon, bool done}) clubNextAction(
  Membership m,
  DateTime now,
) {
  final unanswered = m.unansweredCount(now);
  final dues = m.unpaidDues();
  final unpaid = dues.where((d) => !d.$2.awaitingCheck).length;
  final waiting = dues.length - unpaid;
  if (unanswered > 0) {
    return (
      label: 'Jawab $unanswered sesi mendatang',
      icon: Icons.how_to_reg_outlined,
      done: false,
    );
  }
  if (unpaid > 0) {
    return (
      label: 'Bayar $unpaid iuran',
      icon: Icons.payments_outlined,
      done: false,
    );
  }
  if (waiting > 0) {
    return (
      label: '$waiting bukti menunggu dicek',
      icon: Icons.hourglass_empty,
      done: true,
    );
  }
  return (label: 'Semua beres', icon: Icons.check_circle_outline, done: true);
}

/// Baris ajakan di bawah garis pemisah kartu PB-ku.
class _ActionLine extends StatelessWidget {
  const _ActionLine({required this.membership, required this.now});

  final Membership membership;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final action = clubNextAction(membership, now);
    final color = action.done ? YbColors.success : YbColors.primary;
    return Row(
      children: [
        Icon(action.icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            action.label,
            style: YbText.body(color: color, weight: FontWeight.w700),
          ),
        ),
        Icon(Icons.chevron_right, color: YbColors.muted),
      ],
    );
  }
}

/// Kotak tanggal bergaya kalender: "RAB / 18 / Nov".
class _DateTile extends StatelessWidget {
  const _DateTile({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: YbColors.primarySoft,
        borderRadius: BorderRadius.circular(YbRadius.sm),
      ),
      child: Column(
        children: [
          Text(
            dayShort[date.weekday]!.toUpperCase(),
            style: YbText.body(
              size: 11,
              color: YbColors.primary,
              weight: FontWeight.w800,
            ),
          ),
          Text(
            '${date.day}',
            style: YbText.display(size: 22, color: YbColors.primaryDark),
          ),
          Text(
            monthNames[date.month - 1].substring(0, 3),
            style: YbText.label(color: YbColors.primaryDark),
          ),
        ],
      ),
    );
  }
}

/// Isi kartu PB-ku: tanggal sesi terdekat, dua baris info, lalu satu ajakan.
class _ClubSummary extends StatelessWidget {
  const _ClubSummary({
    required this.membership,
    required this.pb,
    required this.now,
  });

  final Membership membership;
  final Pb pb;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final next = membership.upcoming(now).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (next != null)
              _DateTile(date: next.start)
            else
              YbAvatar(
                initialsOf(pb.name.replaceFirst('PB ', '')),
                photoPath: pb.logoPath,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    next?.title ?? pb.name,
                    style: YbText.body(size: 15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next == null
                        ? 'Belum ada sesi mendatang'
                        : '${next.timeRange} · ${pb.name}',
                    style: YbText.label(),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: YbColors.line),
        ),
        _ActionLine(membership: membership, now: now),
      ],
    );
  }
}

/// P18 PB-ku: daftar PB tempat pengguna tercatat sebagai member.
class ClubListPage extends ConsumerWidget {
  const ClubListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberships = ref.watch(membershipProvider);
    final pbs = ref.watch(pbListProvider);
    final now = ref.watch(nowProvider)();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const PageHeader(title: 'PB-ku'),
            const SizedBox(height: 6),
            Text(
              'PB tempat kamu tercatat sebagai member. Pengurus yang menambahkanmu setelah kamu bergabung.',
              style: YbText.label(),
            ),
            const SizedBox(height: 14),
            ...pbs.when(
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (_, _) => [
                const YbEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'PB-ku gagal dimuat',
                  message: 'Tutup lalu buka lagi aplikasinya.',
                ),
              ],
              data: (list) {
                final rows = [
                  for (final m in memberships)
                    if (list.where((pb) => pb.id == m.pbId).firstOrNull
                        case final pb?)
                      (m, pb),
                ];
                if (rows.isEmpty) {
                  return [
                    YbEmptyState(
                      icon: Icons.groups_outlined,
                      title: 'Belum jadi member PB mana pun',
                      message: 'Cari PB yang cocok, lalu hubungi pengurusnya. Setelah kamu ditambahkan sebagai member, PB-nya muncul di sini.',
                      actionLabel: 'Cari PB',
                      onAction: () => context.go('/cari'),
                    ),
                  ];
                }
                return [
                  for (final (m, pb) in rows) ...[
                    _ClubCard(membership: m, pb: pb, now: now),
                    const SizedBox(height: 10),
                  ],
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClubCard extends StatelessWidget {
  const _ClubCard({
    required this.membership,
    required this.pb,
    required this.now,
  });

  final Membership membership;
  final Pb pb;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return YbCard(
      onTap: () => context.push('/pb-ku/${pb.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(pb.name, style: YbText.display(size: 17)),
          Text(membership.type.label, style: YbText.label()),
          const SizedBox(height: 12),
          _ClubSummary(membership: membership, pb: pb, now: now),
        ],
      ),
    );
  }
}

/// P19 Halaman PB untuk member: jadwal, konfirmasi ikut, dan Iuranku.
class ClubDetailPage extends ConsumerWidget {
  const ClubDetailPage({super.key, required this.pbId});

  final String pbId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref
        .watch(membershipProvider)
        .where((m) => m.pbId == pbId)
        .firstOrNull;
    final pb = ref.watch(pbByIdProvider(pbId));
    final now = ref.watch(nowProvider)();
    final notifier = ref.read(membershipProvider.notifier);

    Widget body(String title, List<Widget> children) => Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            PageHeader(
              title: title,
              trailing: pb.value == null
                  ? null
                  : OutlinedButton(
                      onPressed: () => context.push('/pb/$pbId'),
                      child: const Text('Profil PB'),
                    ),
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );

    return pb.when(
      loading: () =>
          body('PB-ku', [const Center(child: CircularProgressIndicator())]),
      error: (_, _) => body('PB-ku', [
        const YbEmptyState(
          icon: Icons.cloud_off_outlined,
          title: 'Data PB gagal dimuat',
          message: 'Tutup lalu buka lagi aplikasinya.',
        ),
      ]),
      data: (pb) => pb == null || membership == null
          ? body('PB-ku', [
              YbEmptyState(
                icon: Icons.group_off_outlined,
                title: 'Kamu tidak tercatat di PB ini',
                message: 'Mungkin pengurus sudah mengeluarkanmu dari daftar member. Hubungi pengurusnya kalau ini keliru.',
                actionLabel: 'Kembali',
                onAction: () => context.pop(),
              ),
            ])
          : body(pb.name, [
              ClubMemberView(
                pb: pb,
                memberId: membership.memberId,
                type: membership.type,
                events: membership.events,
                now: now,
                onRsvp: (eventId, r) => notifier.setRsvp(pbId, eventId, r),
                onProof: (eventId, path) =>
                    notifier.submitProof(pbId, eventId, path),
                onRefundRequest: (eventId, reason) =>
                    notifier.requestRefund(pbId, eventId, reason),
                system: membership.duesSystem,
              ),
            ]),
    );
  }
}
