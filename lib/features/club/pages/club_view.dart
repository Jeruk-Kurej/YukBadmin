import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/photo.dart';
import '../../../core/widgets/yb_widgets.dart';
import '../../manage/data/manage_models.dart';
import '../../manage/pages/manage_widgets.dart';
import '../../pb/data/pb_models.dart';

String _dateLong(DateTime d) =>
    '${dayNames[d.weekday]}, ${d.day} ${monthNames[d.month - 1].substring(0, 3)}';

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

/// Isi halaman PB untuk member (P19–P28 di Final Design v4): sesi
/// berikutnya dengan konfirmasi ikut, tagihan milik sendiri, riwayat, dan
/// cara bayar. Dipakai di PB-ku dan di pratinjau "Lihat sebagai member"
/// milik pengurus, jadi tidak membaca provider sendiri. Member hanya
/// menjawab ikut, mengirim bukti transfer, dan mengajukan pengembalian.
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
    required this.onRefundRequest,
    this.system = const DuesSystem(),
    this.showContact = true,
  });

  final Pb pb;
  final String memberId;
  final MemberType type;
  final List<SessionEvent> events;
  final DateTime now;
  final DuesSystem system;
  final void Function(String eventId, Rsvp rsvp) onRsvp;
  final void Function(String eventId, String path) onProof;
  final void Function(String eventId, String reason) onRefundRequest;

  /// Di pratinjau pengurus, tombol hubungi pengurus disembunyikan.
  final bool showContact;

  /// Nama panggilan pengurus: "Pak Hendra" tetap utuh, "Bryan Carlie"
  /// cukup "Bryan". Sapaan tidak ditebak dari nama.
  String get _managerShort {
    final parts = pb.manager.name.trim().split(RegExp(r'\s+'));
    const titles = {'pak', 'bu', 'bapak', 'ibu', 'kak', 'mas', 'mbak'};
    if (parts.length > 1 && titles.contains(parts.first.toLowerCase())) {
      return '${parts[0]} ${parts[1]}';
    }
    return parts.first;
  }

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

  Future<void> _cancel(BuildContext context, SessionEvent e) async {
    final due = e.dues[memberId];
    final hoursLeft = e.start.difference(now).inMinutes / 60;
    final late = hoursLeft < system.cancelHours;
    final paid = due?.paid ?? false;
    final checking = due?.awaitingCheck ?? false;
    final ok = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                late
                    ? 'Sesi mulai dalam ${hoursLeft.ceil()} jam'
                    : 'Batal ikut sesi ${_dateLong(e.start)}?',
                style: YbText.display(size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                checking
                    ? 'Bukti transfermu tetap dicek pengurus. Kalau disetujui, uangnya mengikuti aturan pembatalan.'
                    : !paid
                    ? 'Kamu belum bayar, jadi tagihannya ikut dihapus.'
                    : late
                    ? 'Uang tidak otomatis dikembalikan. Kamu bisa mengajukan ke pengurus.'
                    : 'Kamu sudah bayar, jadi uangmu dikembalikan pengurus.',
                style: YbText.body(color: YbColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: YbColors.error,
                  foregroundColor: YbColors.onError,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(late && paid ? 'Tetap batal ikut' : 'Batal ikut'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Tetap ikut'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) onRsvp(e.id, Rsvp.tidak);
  }

  Future<void> _requestRefund(BuildContext context, SessionEvent e) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RefundSheet(),
    );
    if (reason == null || !context.mounted) return;
    onRefundRequest(e.id, reason);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan terkirim ke pengurus')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = events.where((e) => e.end.isAfter(now)).toList()
      ..sort((a, b) => a.start.compareTo(b.start));
    final next = upcoming.firstOrNull;

    // Tagihan yang masih perlu perhatian: belum lunas, atau urusan
    // pengembalian yang belum selesai. Riwayat: yang sudah lunas.
    final open = <(SessionEvent, Due)>[];
    final history = <(SessionEvent, Due)>[];
    for (final e in events) {
      final due = e.dues[memberId];
      if (due == null) continue;
      final refund = due.refund;
      if (refund != null && refund.status != RefundStatus.selesai) {
        open.add((e, due));
      } else if (!due.paid && refund == null) {
        open.add((e, due));
      } else {
        history.add((e, due));
      }
    }
    open.sort((a, b) => a.$1.start.compareTo(b.$1.start));
    history.sort((a, b) => b.$1.start.compareTo(a.$1.start));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        YbSectionTitle('Sesi berikutnya'),
        const SizedBox(height: 10),
        if (next == null)
          const YbEmptyState(
            icon: Icons.calendar_today_outlined,
            title: 'Belum ada sesi mendatang',
            message: 'Sesi baru muncul di sini setelah pengurus membuatnya.',
          )
        else
          _NextSessionCard(
            event: next,
            mine: next.rsvps[memberId],
            now: now,
            onIkut: () => onRsvp(next.id, Rsvp.ikut),
            onTidak: () => next.rsvps[memberId] == Rsvp.ikut
                ? _cancel(context, next)
                : onRsvp(next.id, Rsvp.tidak),
          ),
        for (final e in upcoming.skip(1).take(3)) ...[
          const SizedBox(height: 10),
          _NextSessionCard(
            event: e,
            mine: e.rsvps[memberId],
            now: now,
            compact: true,
            onIkut: () => onRsvp(e.id, Rsvp.ikut),
            onTidak: () => e.rsvps[memberId] == Rsvp.ikut
                ? _cancel(context, e)
                : onRsvp(e.id, Rsvp.tidak),
          ),
        ],
        const SizedBox(height: 28),
        YbSectionTitle('Tagihan'),
        const SizedBox(height: 10),
        if (open.isEmpty)
          YbCard(
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, color: YbColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tidak ada tagihan. Semua beres.',
                    style: YbText.body(weight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        for (final (e, due) in open) ...[
          _BillCard(
            event: e,
            due: due,
            usage: e.usage[memberId],
            system: system,
            managerShort: _managerShort,
            onSendProof: () => _sendProof(context, ref, e),
            onRequestRefund: () => _requestRefund(context, e),
          ),
          const SizedBox(height: 10),
        ],
        if (history.isNotEmpty) ...[
          const SizedBox(height: 18),
          YbSectionTitle('Riwayat'),
          const SizedBox(height: 10),
          YbGroup(
            children: [
              for (final (e, due) in history.take(6))
                YbListRow(
                  title: _dateLong(e.start),
                  subtitle: '${e.title} · ${formatRupiah(due.amount)}',
                  trailing: due.refund?.status == RefundStatus.selesai
                      ? const YbTag('Dikembalikan', tone: YbTagTone.neutral)
                      : const YbTag(
                          'Lunas',
                          tone: YbTagTone.success,
                          icon: Icons.check,
                        ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 28),
        YbSectionTitle('Cara bayar'),
        const SizedBox(height: 10),
        YbGroup(
          children: [
            YbListRow(
              icon: Icons.account_balance_wallet_outlined,
              title: system.timingShort,
              subtitle: system.explain(pb.feePerSession),
            ),
            _PaymentInfoRow(info: pb.paymentInfo),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, size: 16, color: YbColors.muted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Pembayaran di luar app. Jadwal, nominal, dan status iuran diatur pengurus PB.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
            ),
          ],
        ),
        if (showContact) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
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
            label: Text('Tanya $_managerShort'),
          ),
        ],
      ],
    );
  }
}

class _NextSessionCard extends StatelessWidget {
  const _NextSessionCard({
    required this.event,
    required this.mine,
    required this.now,
    required this.onIkut,
    required this.onTidak,
    this.compact = false,
  });

  final SessionEvent event;
  final Rsvp? mine;
  final DateTime now;
  final VoidCallback onIkut;
  final VoidCallback onTidak;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final started = !event.start.isAfter(now);
    final going = event.goingCount;
    final peopleLine = mine == Rsvp.ikut
        ? '$going pemain ikut, termasuk kamu'
        : mine == Rsvp.tidak
        ? 'Kamu batal ikut'
        : going == 0
        ? 'Belum ada yang konfirmasi'
        : '$going pemain ikut';
    return YbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${event.title} · ${_dateLong(event.start)}',
            style: YbText.body(
              size: compact ? 15 : 17,
              weight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${event.timeRange} · ${event.venue} · ${event.courts} lapangan',
            style: YbText.body(size: 14, color: YbColors.muted),
          ),
          if (!compact) ...[
            const SizedBox(height: 8),
            Text(
              peopleLine,
              style: YbText.body(size: 14, color: YbColors.muted),
            ),
          ],
          const SizedBox(height: 12),
          if (started)
            Text(
              'Sesi sudah dimulai. Jawabanmu: ${mine?.label ?? 'belum menjawab'}.',
              style: YbText.body(size: 14, color: YbColors.muted),
            )
          else
            YbSegmented<Rsvp>(
              options: const [
                (Rsvp.ikut, 'Ikut', Icons.check_rounded),
                (Rsvp.tidak, 'Tidak ikut', null),
              ],
              selected: mine,
              onChanged: (r) {
                if (r == mine) return;
                r == Rsvp.ikut ? onIkut() : onTidak();
              },
            ),
        ],
      ),
    );
  }
}

/// Kartu satu tagihan: status, nominal besar, rincian (kalau dihitung per
/// orang), lalu satu aksi yang sesuai statusnya.
class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.event,
    required this.due,
    required this.usage,
    required this.system,
    required this.managerShort,
    required this.onSendProof,
    required this.onRequestRefund,
  });

  final SessionEvent event;
  final Due due;
  final Usage? usage;
  final DuesSystem system;
  final String managerShort;
  final VoidCallback onSendProof;
  final VoidCallback onRequestRefund;

  @override
  Widget build(BuildContext context) {
    final refund = due.refund;
    final proof = due.proof;
    final rejected = proof?.status == ProofStatus.ditolak;

    final (YbTag tag, String? note, Widget? action) = switch (refund?.status) {
      RefundStatus.perlu => (
        const YbTag('Akan dikembalikan', tone: YbTagTone.pending),
        refund!.requested
            ? 'Pengajuanmu disetujui. $managerShort akan mentransfer balik.'
            : 'Kamu batal tepat waktu. $managerShort akan mentransfer balik.',
        null,
      ),
      RefundStatus.diajukan => (
        const YbTag('Pengembalian diajukan', tone: YbTagTone.pending),
        'Alasan: ${refund!.reason?.toLowerCase() ?? '-'}. $managerShort akan memutuskan dan bisa menghubungimu.',
        null,
      ),
      RefundStatus.tidakKembali => (
        const YbTag('Tidak dikembalikan', tone: YbTagTone.neutral),
        refund!.rejected
            ? 'Pengajuanmu ditolak $managerShort.'
            : 'Batal kurang dari ${system.cancelHours} jam. Ada alasan mendesak? Ajukan ke pengurus.',
        refund.rejected || refund.requested
            ? null
            : OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: onRequestRefund,
                child: const Text('Ajukan pengembalian'),
              ),
      ),
      _ when due.awaitingCheck => (
        const YbTag(
          'Menunggu dicek',
          tone: YbTagTone.pending,
          icon: Icons.hourglass_empty,
        ),
        'Bukti terkirim. Status jadi lunas setelah pengurus mengeceknya.',
        null,
      ),
      _ when rejected => (
        const YbTag(
          'Bukti perlu diganti',
          tone: YbTagTone.error,
          icon: Icons.error_outline,
        ),
        'Alasan pengurus: ${proof!.reason ?? '-'}',
        FilledButton(
          onPressed: onSendProof,
          child: const Text('Kirim bukti baru'),
        ),
      ),
      _ => (
        const YbTag(
          'Belum bayar',
          tone: YbTagTone.warning,
          icon: Icons.schedule,
        ),
        system.timing == DuesTiming.sebelum
            ? 'Batas bayar ${dayShort[event.start.weekday]}, ${event.start.day} ${monthNames[event.start.month - 1].substring(0, 3)} ${_hm(event.start)}'
            : null,
        FilledButton(
          onPressed: onSendProof,
          child: const Text('Kirim bukti transfer'),
        ),
      ),
    };

    return YbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: Alignment.centerLeft, child: tag),
          const SizedBox(height: 10),
          Text(
            '${event.title} · ${_dateLong(event.start)}',
            style: YbText.body(size: 14, color: YbColors.muted),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatRupiah(due.amount),
              style: YbText.score(size: 34),
            ),
          ),
          if (usage case final u? when u.matches + u.shuttles > 0) ...[
            const SizedBox(height: 12),
            _Line(
              '${u.matches} match',
              formatRupiah(u.matches * system.matchPrice),
              '${formatRupiah(system.matchPrice)} per match',
            ),
            _Line(
              '${u.shuttles} kok',
              formatRupiah(u.shuttles * system.shuttlePrice),
              '${formatRupiah(system.shuttlePrice)} per kok',
            ),
          ],
          if (note != null) ...[
            const SizedBox(height: 8),
            Text(note, style: YbText.body(size: 14, color: YbColors.muted)),
          ],
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.title, this.amount, this.hint);

  final String title;
  final String amount;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: YbText.body(weight: FontWeight.w500)),
                Text(hint, style: YbText.body(size: 13, color: YbColors.muted)),
              ],
            ),
          ),
          Text(amount, style: YbText.body(weight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PaymentInfoRow extends StatelessWidget {
  const _PaymentInfoRow({required this.info});

  final String? info;

  @override
  Widget build(BuildContext context) {
    final text = info?.trim() ?? '';
    return YbListRow(
      icon: Icons.account_balance_outlined,
      title: text.isEmpty ? 'Cara transfer belum ditulis' : text,
      subtitle: text.isEmpty ? 'Tanyakan ke pengurus lewat WhatsApp.' : null,
      trailing: text.isEmpty
          ? null
          : TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cara bayar disalin')),
                  );
                }
              },
              child: const Text('Salin'),
            ),
    );
  }
}

/// P28b: alasan mengajukan pengembalian setelah batal mendadak.
class _RefundSheet extends StatefulWidget {
  const _RefundSheet();

  @override
  State<_RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<_RefundSheet> {
  static const _reasons = [
    'Sakit',
    'Keperluan mendadak',
    'Cuaca atau transportasi',
    'Lainnya',
  ];
  String? _reason;
  final _other = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _other.dispose();
    super.dispose();
  }

  void _submit() {
    if (_reason == null) {
      setState(
        () => _error = 'Pilih alasan dulu supaya pengurus bisa memutuskan.',
      );
      return;
    }
    if (_reason == 'Lainnya' && _other.text.trim().isEmpty) {
      setState(
        () => _error = 'Tulis alasannya singkat, misalnya "anak sakit".',
      );
      return;
    }
    Navigator.of(context)
        .pop(_reason == 'Lainnya' ? _other.text.trim() : _reason);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          24,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ajukan pengembalian', style: YbText.display(size: 22)),
              const SizedBox(height: 16),
              Text('Alasan', style: YbText.body(weight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in _reasons)
                    YbChoiceChip(
                      label: r,
                      selected: _reason == r,
                      onTap: () => setState(() {
                        _reason = r;
                        _error = null;
                      }),
                    ),
                ],
              ),
              if (_reason == 'Lainnya') ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _other,
                  decoration: const InputDecoration(
                    hintText: 'Tulis alasannya',
                  ),
                ),
              ],
              if (_error != null) FieldError(_error!),
              const SizedBox(height: 12),
              Text(
                'Pengurus bisa menyetujui atau menolak. Uang belum tentu kembali.',
                style: YbText.body(size: 13, color: YbColors.muted),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submit,
                child: const Text('Kirim pengajuan'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Batal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
