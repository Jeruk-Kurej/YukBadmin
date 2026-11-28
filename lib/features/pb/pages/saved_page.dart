import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/state/manage_providers.dart' show nowProvider;
import '../data/pb_models.dart' show Pb, dayNames;
import '../state/join_status.dart';
import '../state/providers.dart';
import 'contact_sheet.dart';
import 'pb_card.dart';

/// P7 PB tersimpan: PB yang sudah dihubungi beserta status gabungnya, lalu PB
/// yang disimpan untuk dibandingkan.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  static const _months = [
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

  static String _date(DateTime t) =>
      '${dayNames[t.weekday]!.substring(0, 3)}, ${t.day} ${_months[t.month - 1]}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedPbProvider);
    final contacted = ref.watch(contactedPbProvider);
    final records = ref.watch(joinStatusProvider);
    final now = ref.watch(nowProvider)();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const Align(alignment: Alignment.centerLeft, child: YbBackButton()),
            const SizedBox(height: 20),
            const YbPageTitle('PB tersimpan'),
            const SizedBox(height: 20),
            if (contacted.isNotEmpty) ...[
              YbSectionTitle('Sudah kamu hubungi'),
              const SizedBox(height: 10),
              YbGroup(
                children: [
                  for (final (pb, at) in contacted)
                    YbListRow(
                      title: pb.name,
                      subtitle: 'Dihubungi lewat WhatsApp · ${_date(at)}',
                      trailing: _JoinTag(
                        record: joinRecordFor(records, pb.id, at),
                        now: now,
                      ),
                      onTap: () => showJoinStatusSheet(context, pb, at),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Balasan pengurus ada di WhatsApp. Ketuk PB untuk menandai statusnya.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 24),
            ],
            ...saved.when(
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                YbEmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: 'Daftar PB gagal dimuat',
                  message: 'Tutup lalu buka lagi halaman ini.',
                  actionLabel: 'Coba lagi',
                  onAction: () => ref.invalidate(pbListProvider),
                ),
              ],
              data: (list) => [
                if (list.isEmpty)
                  YbEmptyState(
                    icon: Icons.star_outline_rounded,
                    title: 'Belum ada PB tersimpan',
                    message: 'Ketuk bintang di kartu PB supaya gampang kamu bandingkan nanti.',
                    actionLabel: 'Cari PB',
                    onAction: () => context.go('/cari'),
                  )
                else ...[
                  if (contacted.isNotEmpty) ...[
                    YbSectionTitle('Disimpan'),
                    const SizedBox(height: 10),
                  ],
                  for (final pb in list) ...[
                    PbListCard(pb: pb),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Mau simpan PB lain?',
                    textAlign: TextAlign.center,
                    style: YbText.body(size: 14, color: YbColors.muted),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: () => context.go('/cari'),
                    icon: const Icon(Icons.search_rounded, size: 20),
                    label: const Text('Cari PB'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Label status gabung di baris PB yang sudah dihubungi.
class _JoinTag extends StatelessWidget {
  const _JoinTag({required this.record, required this.now});

  final JoinRecord record;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (record.needsFollowUp(now)) {
      return const YbTag('Belum dibalas', tone: YbTagTone.warning);
    }
    return YbTag(
      record.status.label,
      tone: switch (record.status) {
        JoinStatus.menunggu => YbTagTone.pending,
        JoinStatus.dibalas => YbTagTone.primarySoft,
        JoinStatus.diterima => YbTagTone.success,
        JoinStatus.batal => YbTagTone.neutral,
      },
    );
  }
}

/// Lembar untuk menandai status gabung PB yang sudah dihubungi.
Future<void> showJoinStatusSheet(BuildContext context, Pb pb, DateTime at) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _JoinStatusSheet(pb: pb, contactedAt: at),
    );

class _JoinStatusSheet extends ConsumerWidget {
  const _JoinStatusSheet({required this.pb, required this.contactedAt});

  final Pb pb;
  final DateTime contactedAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider)();
    final record = joinRecordFor(
      ref.watch(joinStatusProvider),
      pb.id,
      contactedAt,
    );
    final days = now.difference(contactedAt).inDays;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(pb.name, style: YbText.display(size: 22)),
            const SizedBox(height: 4),
            Text(
              days <= 0
                  ? 'Kamu menghubungi pengurus hari ini.'
                  : 'Kamu menghubungi pengurus $days hari lalu.',
              style: YbText.body(size: 14, color: YbColors.muted),
            ),
            const SizedBox(height: 16),
            YbGroup(
              children: [
                for (final s in JoinStatus.values)
                  Semantics(
                    selected: s == record.status,
                    child: YbListRow(
                      title: s.label,
                      subtitle: s.hint,
                      trailing: s == record.status
                          ? Icon(Icons.check_rounded, color: YbColors.primary)
                          : const SizedBox(width: 24),
                      onTap: () => ref
                          .read(joinStatusProvider.notifier)
                          .set(pb.id, s, now),
                    ),
                  ),
              ],
            ),
            if (record.status == JoinStatus.diterima) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: YbColors.successSoft,
                  borderRadius: BorderRadius.circular(YbRadius.md),
                ),
                child: Text(
                  'Minta pengurus mencatatmu sebagai member di YukBadmin, supaya jadwal dan iuran PB ini muncul di PB-ku.',
                  style: YbText.body(size: 13, color: YbColors.success),
                ),
              ),
            ],
            if (record.status == JoinStatus.menunggu) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showContactSheet(context, pb);
                },
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: const Text('Hubungi lagi lewat WhatsApp'),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/pb/${pb.id}');
              },
              child: const Text('Lihat detail PB'),
            ),
          ],
        ),
      ),
    );
  }
}
