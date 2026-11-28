import '../../club/data/club_models.dart';
import '../../manage/data/manage_models.dart';
import '../../pb/data/pb_models.dart' show dayShort;
import '../../../core/widgets/yb_widgets.dart' show formatRupiah;

/// Data turunan untuk Riwayat transaksi dan Notifikasi pemain. Semuanya
/// dihitung dari PB-ku (jadwal dan iuran), tanpa sumber data baru.

/// Satu baris iuran milik pengguna di salah satu PB-nya.
class DueEntry {
  const DueEntry({required this.pbId, required this.event, required this.due});

  final String pbId;
  final SessionEvent event;
  final Due due;

  DueState get state {
    if (due.refund != null) return DueState.refund;
    if (due.paid) return DueState.paid;
    if (due.awaitingCheck) return DueState.checking;
    if (due.proof?.status == ProofStatus.ditolak) return DueState.rejected;
    if (due.cancelledAt != null) return DueState.cancelled;
    return DueState.unpaid;
  }
}

enum DueState {
  paid('Lunas'),
  checking('Menunggu dicek'),
  rejected('Bukti perlu diganti'),
  unpaid('Belum dibayar'),
  cancelled('Batal ikut'),
  refund('Pengembalian');

  const DueState(this.label);
  final String label;

  bool get open => this == unpaid || this == rejected || this == checking;
}

/// Semua iuran pengguna di semua PB-ku, dari sesi terbaru.
List<DueEntry> dueEntries(List<Membership> memberships) => [
  for (final m in memberships)
    for (final e in m.events)
      if (e.dues[m.memberId] case final due?)
        DueEntry(pbId: m.pbId, event: e, due: due),
]..sort((a, b) => b.event.start.compareTo(a.event.start));

/// Satu notifikasi yang disusun dari jadwal dan iuran di PB-ku.
class PlayerNotice {
  const PlayerNotice({
    required this.pbId,
    required this.title,
    required this.message,
    required this.time,
    required this.kind,
    this.action,
    String? route,
  }) : route = route ?? '/pb-ku/$pbId';

  final String pbId;

  /// Halaman yang dibuka tombol aksinya.
  final String route;
  final String title;
  final String message;
  final DateTime time;
  final NoticeKind kind;

  /// Label tombol, kalau notifikasi ini butuh tindakan.
  final String? action;

  bool get needsAction => action != null;
}

enum NoticeKind { session, rejected, unpaid, paid, followUp }

/// Notifikasi pemain dari data PB-ku: sesi 2 hari ke depan yang belum
/// dijawab, bukti yang ditolak, iuran belum dibayar, dan iuran yang baru
/// tercatat lunas (7 hari terakhir). [followUps] berisi PB yang sudah
/// dihubungi tapi masih menunggu balasan pengurus lebih dari 2 hari.
List<PlayerNotice> playerNotices(
  List<Membership> memberships,
  DateTime now,
  Map<String, String> pbNames, {
  List<(String, DateTime)> followUps = const [],
}) {
  final out = <PlayerNotice>[
    for (final (pbId, since) in followUps)
      PlayerNotice(
        pbId: pbId,
        title: '${pbNames[pbId] ?? 'PB'} belum membalas',
        message:
            'Sudah ${now.difference(since).inDays} hari sejak kamu menghubungi pengurus. Hubungi lagi, atau tandai statusnya kalau sudah dibalas.',
        time: since,
        kind: NoticeKind.followUp,
        action: 'Lihat PB tersimpan',
        route: '/tersimpan',
      ),
  ];
  for (final m in memberships) {
    final name = pbNames[m.pbId] ?? 'PB';
    for (final e in m.events) {
      final due = e.dues[m.memberId];
      final soon =
          e.start.isAfter(now) &&
          e.start.difference(now) <= const Duration(days: 2);
      if (soon && !e.rsvps.containsKey(m.memberId)) {
        out.add(
          PlayerNotice(
            pbId: m.pbId,
            title: '${e.title} ${dayShort[e.start.weekday]}, ${_hm(e.start)}',
            message:
                '$name di ${e.venue}. Kamu belum menjawab ikut atau tidak.',
            time: e.start,
            kind: NoticeKind.session,
            action: 'Jawab sekarang',
          ),
        );
      }
      if (due == null) continue;
      final entry = DueEntry(pbId: m.pbId, event: e, due: due);
      switch (entry.state) {
        case DueState.rejected:
          out.add(
            PlayerNotice(
              pbId: m.pbId,
              title: 'Bukti transfer perlu diganti',
              message:
                  'Pengurus $name: ${due.proof?.reason ?? 'bukti belum bisa diterima.'}',
              time: due.proof!.sentAt,
              kind: NoticeKind.rejected,
              action: 'Kirim ulang bukti',
            ),
          );
        case DueState.unpaid when due.billable:
          out.add(
            PlayerNotice(
              pbId: m.pbId,
              title: 'Iuran ${formatRupiah(due.amount)} belum dibayar',
              message: '$name · ${e.title}, ${formatDate(e.start)}.',
              time: e.start,
              kind: NoticeKind.unpaid,
              action: 'Bayar iuran',
            ),
          );
        case DueState.paid
            when due.paidAt != null &&
                now.difference(due.paidAt!) <= const Duration(days: 7):
          out.add(
            PlayerNotice(
              pbId: m.pbId,
              title: 'Iuran tercatat lunas',
              message:
                  'Pembayaran ${formatRupiah(due.amount)} untuk $name sudah disetujui.',
              time: due.paidAt!,
              kind: NoticeKind.paid,
            ),
          );
        default:
          break;
      }
    }
  }
  out.sort((a, b) {
    if (a.needsAction != b.needsAction) return a.needsAction ? -1 : 1;
    return b.time.compareTo(a.time);
  });
  return out;
}

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';
