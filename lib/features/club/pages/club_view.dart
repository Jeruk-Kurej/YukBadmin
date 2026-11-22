import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/data/manage_models.dart';
import '../../manage/pages/manage_shell.dart' show formatSessionDate;
import '../../manage/pages/manage_widgets.dart';
import '../../pb/data/pb_models.dart';

/// Isi halaman PB untuk member (P19): jadwal dengan konfirmasi ikut,
/// iuran milik sendiri, dan cara bayar. Dipakai di PB-ku dan di pratinjau
/// "Lihat sebagai member" milik pengurus, jadi tidak membaca provider
/// sendiri. Semua isian hanya bisa diubah pengurus; member hanya menjawab
/// ikut atau tidak dan mengirim bukti transfer.
class ClubMemberView extends ConsumerWidget {
  const ClubMemberView({
    super.key,
    required this.pb,
    required this.memberId,
    required this.type,
    required this.events,
    required this.now,
    required this.onRsvp,
    required this.onProof,
    this.showContact = true,
  });

  final Pb pb;
  final String memberId;
  final MemberType type;
  final List<SessionEvent> events;
  final DateTime now;
  final void Function(String eventId, Rsvp rsvp) onRsvp;
  final void Function(String eventId, String path) onProof;

  /// Di pratinjau pengurus, tombol hubungi pengurus disembunyikan.
  final bool showContact;

  Future<void> _sendProof(
    BuildContext context,
    WidgetRef ref,
    SessionEvent event,
  ) async {
    final change = await changePhoto(context, ref, title: 'Bukti transfer');
    final path = change?.path;
    if (path == null || !context.mounted) return;
    onProof(event.id, path);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bukti terkirim. Pengurus akan mengeceknya.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = events.where((e) => e.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final myDues =
        [
          for (final e in events)
            if (e.dues[memberId] case final due?) (e, due),
        ]..sort((a, b) {
          // Yang belum lunas di atas, lalu dari sesi terbaru.
          if (a.$2.paid != b.$2.paid) return a.$2.paid ? 1 : -1;
          return b.$1.start.compareTo(a.$1.start);
        });
    final unpaid = myDues
        .where((d) => !d.$2.paid)
        .fold(0, (sum, d) => sum + d.$2.amount);
    final paid = myDues
        .where((d) => d.$2.paid)
        .fold(0, (sum, d) => sum + d.$2.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            YbTag(type.label, icon: Icons.badge_outlined),
            YbTag('Level ${pb.levelRange}', tone: YbTagTone.neutral),
          ],
        ),
        const SizedBox(height: 18),
        Text('Jadwal', style: YbText.display(size: 18)),
        const SizedBox(height: 4),
        Text(
          'Kabari pengurus apakah kamu ikut, supaya lapangan dan shuttlecock cukup.',
          style: YbText.label(),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          const YbEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Belum ada sesi mendatang',
            message: 'Sesi baru muncul di sini setelah pengurus membuatnya.',
          ),
        for (final e in upcoming.take(4)) ...[
          _SessionRsvpCard(
            event: e,
            mine: e.rsvps[memberId],
            now: now,
            onRsvp: (r) => onRsvp(e.id, r),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 12),
        Text('Iuranku', style: YbText.display(size: 18)),
        const SizedBox(height: 10),
        if (myDues.isEmpty)
          const YbEmptyState(
            icon: Icons.payments_outlined,
            title: 'Belum ada iuran tercatat',
            message: 'Iuran muncul setelah pengurus mencatat kehadiranmu di sebuah sesi.',
          )
        else ...[
          Row(
            children: [
              Expanded(
                child: AmountTile(
                  amount: unpaid,
                  label: 'Belum dibayar',
                  positive: false,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AmountTile(
                  amount: paid,
                  label: 'Sudah lunas',
                  positive: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (e, due) in myDues) ...[
            _DueCard(
              event: e,
              due: due,
              now: now,
              onSendProof: () => _sendProof(context, ref, e),
            ),
            const SizedBox(height: 8),
          ],
        ],
        const SizedBox(height: 12),
        _PaymentInfoCard(info: pb.paymentInfo),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 18, color: YbColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Jadwal, nominal, dan status iuran diatur pengurus PB. Kalau ada yang keliru, hubungi pengurus.',
                style: YbText.label(),
              ),
            ),
          ],
        ),
        if (showContact) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: () async {
              final ok = await openWhatsApp(
                pb.manager.whatsapp,
                'Halo ${pb.manager.name}, saya member ${pb.name}. ',
              );
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'WhatsApp tidak bisa dibuka. Hubungi ${displayWhatsapp(pb.manager.whatsapp)} secara manual.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: Text('Hubungi ${pb.manager.name}'),
          ),
        ],
      ],
    );
  }
}

class _SessionRsvpCard extends StatelessWidget {
  const _SessionRsvpCard({
    required this.event,
    required this.mine,
    required this.now,
    required this.onRsvp,
  });

  final SessionEvent event;
  final Rsvp? mine;
  final DateTime now;
  final ValueChanged<Rsvp> onRsvp;

  @override
  Widget build(BuildContext context) {
    final date = formatSessionDate(event.start, now);
    final started = !event.start.isAfter(now);
    return YbCard(
      highlight: date == 'Hari ini',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              YbTag(date, tone: YbTagTone.primary),
              Text(event.title, style: YbText.display(size: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${event.timeRange} · ${event.venue}',
            style: YbText.body(weight: FontWeight.w600),
          ),
          Text(
            event.goingCount == 0
                ? 'Belum ada yang konfirmasi'
                : '${event.goingCount} orang ikut',
            style: YbText.label(),
          ),
          const SizedBox(height: 10),
          if (started)
            Text(
              'Sesi sudah dimulai. Jawabanmu: ${mine?.label ?? 'belum menjawab'}.',
              style: YbText.label(),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                YbChoiceChip(
                  label: 'Ikut',
                  icon: Icons.check,
                  selected: mine == Rsvp.ikut,
                  onTap: () => onRsvp(Rsvp.ikut),
                ),
                YbChoiceChip(
                  label: 'Tidak ikut',
                  icon: Icons.close,
                  selected: mine == Rsvp.tidak,
                  onTap: () => onRsvp(Rsvp.tidak),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DueCard extends StatelessWidget {
  const _DueCard({
    required this.event,
    required this.due,
    required this.now,
    required this.onSendProof,
  });

  final SessionEvent event;
  final Due due;
  final DateTime now;
  final VoidCallback onSendProof;

  @override
  Widget build(BuildContext context) {
    final proof = due.proof;
    final rejected = !due.paid && proof?.status == ProofStatus.ditolak;
    final Widget tag = due.paid
        ? const YbTag('Lunas', tone: YbTagTone.success, icon: Icons.check)
        : due.awaitingCheck
        ? const YbTag(
            'Menunggu dicek',
            tone: YbTagTone.accent,
            icon: Icons.hourglass_empty,
          )
        : rejected
        ? const YbTag('Bukti ditolak', tone: YbTagTone.primarySoft)
        : const YbTag('Belum bayar', tone: YbTagTone.primarySoft);

    return YbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: YbText.body(size: 15, weight: FontWeight.w700),
                    ),
                    Text(
                      '${formatSessionDate(event.start, now)} · ${formatRupiah(due.amount)}',
                      style: YbText.label(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(child: tag),
            ],
          ),
          if (rejected && proof?.reason != null) ...[
            const SizedBox(height: 8),
            FieldError('Alasan pengurus: ${proof!.reason}'),
          ],
          if (due.awaitingCheck) ...[
            const SizedBox(height: 8),
            Text(
              'Bukti transfer terkirim. Status jadi lunas setelah pengurus mengeceknya.',
              style: YbText.label(),
            ),
          ],
          if (!due.paid && !due.awaitingCheck) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onSendProof,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                rejected ? 'Kirim ulang bukti' : 'Kirim bukti transfer',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  const _PaymentInfoCard({required this.info});

  final String? info;

  @override
  Widget build(BuildContext context) {
    final text = info?.trim() ?? '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: YbColors.accentSoft,
        borderRadius: BorderRadius.circular(YbRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 18,
                color: YbColors.ink,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cara bayar iuran',
                  style: YbText.body(weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text.isEmpty
                ? 'Pengurus belum menulis cara bayar. Tanyakan lewat WhatsApp.'
                : text,
            style: YbText.body(),
          ),
          const SizedBox(height: 4),
          Text(
            'Pembayaran dilakukan di luar app. Setelah transfer, kirim buktinya di sini.',
            style: YbText.label(color: YbColors.ink),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cara bayar disalin')),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Salin'),
            ),
          ],
        ],
      ),
    );
  }
}
