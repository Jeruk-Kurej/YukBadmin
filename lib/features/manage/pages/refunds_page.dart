import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../pb/data/pb_models.dart' show dayNames;
import '../data/manage_models.dart';
import '../state/manage_providers.dart';
import 'manage_widgets.dart';

/// K24 Pembatalan dan pengembalian: member yang batal setelah bayar.
/// Pengurus mentransfer balik di luar app, lalu menandainya di sini.
class RefundsPage extends ConsumerWidget {
  const RefundsPage({super.key});

  static String _when(DateTime t) =>
      '${dayNames[t.weekday]}, ${t.day} ${monthNames[t.month - 1].substring(0, 3)} '
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(manageProvider);
    final notifier = ref.read(manageProvider.notifier);
    final all = state.refunds;

    List<(SessionEvent, String, Due)> by(RefundStatus s) =>
        all.where((r) => r.$3.refund!.status == s).toList();

    String name(String id) => state.memberById(id)?.name ?? 'Member';
    String initials(String id) => state.memberById(id)?.initials ?? '?';

    String title((SessionEvent, String, Due) r) =>
        '${name(r.$2)} · ${formatRupiah(r.$3.amount)}';

    String cancelLine((SessionEvent, String, Due) r) {
      final refund = r.$3.refund!;
      final days = r.$1.start.difference(refund.cancelledAt).inDays;
      final base = 'Batal ${_when(refund.cancelledAt)}';
      if (refund.requested && refund.status == RefundStatus.perlu) {
        return 'Pengajuan disetujui · alasan: ${refund.reason?.toLowerCase() ?? '-'}';
      }
      if (refund.requested && refund.status == RefundStatus.diajukan) {
        return '$base · alasan: ${refund.reason?.toLowerCase() ?? '-'}';
      }
      if (refund.status == RefundStatus.selesai && refund.doneAt != null) {
        final d = refund.doneAt!;
        return 'Dikembalikan ${dayNames[d.weekday]}, ${d.day} ${monthNames[d.month - 1].substring(0, 3)}';
      }
      if (refund.status == RefundStatus.tidakKembali) {
        return refund.rejected
            ? '$base · pengajuan ditolak'
            : '$base · tidak mengajukan';
      }
      return days >= 1 ? '$base ($days hari sebelum sesi)' : base;
    }

    void undo(String message, VoidCallback revert) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(label: 'Batalkan', onPressed: revert),
          ),
        );
    }

    Widget section(
      String heading,
      List<(SessionEvent, String, Due)> rows,
      Widget Function((SessionEvent, String, Due) r) actions,
    ) {
      if (rows.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            YbSectionTitle(heading),
            const SizedBox(height: 10),
            for (final r in rows) ...[
              YbGroup(
                children: [
                  YbListRow(
                    leading: YbAvatar(initials(r.$2), size: 40),
                    title: title(r),
                    subtitle: cancelLine(r),
                    trailing: switch (r.$3.refund!.status) {
                      RefundStatus.tidakKembali => const YbTag(
                        'Tidak kembali',
                        tone: YbTagTone.neutral,
                      ),
                      RefundStatus.selesai => const YbTag(
                        'Selesai',
                        tone: YbTagTone.success,
                      ),
                      _ => null,
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              actions(r),
              const SizedBox(height: 4),
            ],
          ],
        ),
      );
    }

    final perlu = by(RefundStatus.perlu);
    final diajukan = by(RefundStatus.diajukan);
    final tidak = by(RefundStatus.tidakKembali);
    final selesai = by(RefundStatus.selesai);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            const PageHeader(title: 'Pembatalan'),
            const SizedBox(height: 12),
            YbPageTitle('Pembatalan', subtitle: 'Transfer balik, lalu tandai.'),
            const SizedBox(height: 20),
            if (all.isEmpty)
              const YbEmptyState(
                icon: Icons.undo_rounded,
                title: 'Belum ada pembatalan',
                message: 'Member yang batal ikut setelah membayar akan muncul di sini.',
              ),
            section(
              'Perlu dikembalikan',
              perlu,
              (r) => OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  foregroundColor: YbColors.primary,
                  side: BorderSide(color: YbColors.primary),
                ),
                onPressed: () {
                  notifier.markRefunded(r.$1.id, r.$2);
                  undo(
                    'Pengembalian ke ${name(r.$2)} ditandai selesai',
                    () => notifier.setRefundStatus(
                      r.$1.id,
                      r.$2,
                      RefundStatus.perlu,
                    ),
                  );
                },
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: const Text('Tandai sudah dikembalikan'),
              ),
            ),
            section(
              'Pengajuan pengembalian',
              diajukan,
              (r) => Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final ok = await confirmDestructive(
                          context,
                          title: 'Tolak pengajuan ${name(r.$2)}?',
                          message:
                              'Uang ${formatRupiah(r.$3.amount)} tidak dikembalikan. Member melihat pengajuannya ditolak.',
                          confirmLabel: 'Tolak',
                        );
                        if (ok) {
                          notifier.decideRefund(r.$1.id, r.$2, approve: false);
                        }
                      },
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () {
                        notifier.decideRefund(r.$1.id, r.$2, approve: true);
                        undo(
                          'Pengajuan ${name(r.$2).split(' ').first} disetujui',
                          () => notifier.setRefundStatus(
                            r.$1.id,
                            r.$2,
                            RefundStatus.diajukan,
                          ),
                        );
                      },
                      child: const Text('Setujui'),
                    ),
                  ),
                ],
              ),
            ),
            section(
              'Tidak dikembalikan',
              tidak,
              (_) => const SizedBox.shrink(),
            ),
            section(
              'Sudah dikembalikan',
              selesai,
              (_) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
