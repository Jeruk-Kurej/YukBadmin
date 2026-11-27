import '../../pb/data/pb_models.dart';

const monthNames = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// "Rabu, 18 November"
String formatDate(DateTime d) =>
    '${dayNames[d.weekday]}, ${d.day} ${monthNames[d.month - 1]}';

/// Inisial dua huruf dari nama orang.
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final p = parts.first;
    return p.substring(0, p.length < 2 ? p.length : 2).toUpperCase();
  }
  return (parts.first[0] + parts.elementAt(1)[0]).toUpperCase();
}

/// Mengubah nomor lokal "0812 3456 7890" menjadi "6281234567890" untuk wa.me.
/// Mengembalikan null kalau bukan nomor ponsel Indonesia yang masuk akal.
String? normalizeWhatsapp(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('0')) digits = '62${digits.substring(1)}';
  if (digits.startsWith('8')) digits = '62$digits';
  if (!digits.startsWith('628')) return null;
  if (digits.length < 11 || digits.length > 15) return null;
  return digits;
}

/// "6281234567890" menjadi "0812 3456 7890".
String displayWhatsapp(String normalized) {
  final local = normalized.startsWith('62')
      ? '0${normalized.substring(2)}'
      : normalized;
  final buffer = StringBuffer();
  for (var i = 0; i < local.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(local[i]);
  }
  return buffer.toString();
}

class Member {
  const Member({
    required this.id,
    required this.name,
    required this.type,
    this.level,
    this.whatsapp,
    this.photoPath,
  });

  final String id;
  final String name;
  final MemberType type;
  final Level? level;

  /// Nomor ternormalisasi (62...), kalau diisi.
  final String? whatsapp;

  /// Path foto member di perangkat, kalau diisi.
  final String? photoPath;

  String get initials => initialsOf(name);
  String get typeShort => type == MemberType.tetap ? 'Tetap' : 'Insidental';

  Member copyWith({
    String? name,
    MemberType? type,
    Level? level,
    bool clearLevel = false,
    String? whatsapp,
    bool clearWhatsapp = false,
    String? photoPath,
    bool clearPhoto = false,
  }) => Member(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    level: clearLevel ? null : (level ?? this.level),
    whatsapp: clearWhatsapp ? null : (whatsapp ?? this.whatsapp),
    photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
  );
}

/// Jawaban member atas undangan sesi.
enum Rsvp {
  ikut('Ikut'),
  tidak('Tidak ikut');

  const Rsvp(this.label);
  final String label;
}

enum ProofStatus { menunggu, disetujui, ditolak }

/// Foto bukti transfer yang dikirim member untuk satu iuran.
class PaymentProof {
  const PaymentProof({
    required this.path,
    required this.sentAt,
    this.status = ProofStatus.menunggu,
    this.reason,
  });

  /// Path berkas di perangkat. Nanti diganti URL Supabase Storage.
  final String path;
  final DateTime sentAt;
  final ProofStatus status;

  /// Alasan penolakan dari pengurus, supaya member tahu apa yang diperbaiki.
  final String? reason;

  PaymentProof copyWith({ProofStatus? status, String? reason}) => PaymentProof(
    path: path,
    sentAt: sentAt,
    status: status ?? this.status,
    reason: reason,
  );
}

/// Iuran satu member untuk satu sesi.
class Due {
  const Due({
    required this.amount,
    this.paid = false,
    this.proof,
    this.refund,
    this.paidAt,
    this.cancelledAt,
  });

  final int amount;
  final bool paid;

  /// Bukti transfer terakhir, kalau member mengirimnya.
  final PaymentProof? proof;

  /// Pengembalian uang setelah member batal ikut padahal sudah bayar.
  final Refund? refund;

  /// Kapan ditandai lunas, untuk riwayat pembayaran (K9f).
  final DateTime? paidAt;

  /// Diisi kalau member batal ikut saat bukti transfernya belum dicek. Uang
  /// mungkin sudah terkirim, jadi catatannya disimpan sampai pengurus memeriksa.
  final DateTime? cancelledAt;

  /// Masih dihitung sebagai iuran: tidak sedang dikembalikan dan bukan tagihan
  /// belum lunas milik member yang sudah batal.
  bool get billable => refund == null && (paid || cancelledAt == null);

  /// Bukti sudah dikirim dan menunggu dicek pengurus.
  bool get awaitingCheck =>
      !paid && refund == null && proof?.status == ProofStatus.menunggu;

  Due copyWith({
    int? amount,
    bool? paid,
    PaymentProof? proof,
    bool clearProof = false,
    Refund? refund,
    bool clearRefund = false,
    DateTime? paidAt,
    bool clearPaidAt = false,
    DateTime? cancelledAt,
    bool clearCancelledAt = false,
  }) => Due(
    amount: amount ?? this.amount,
    paid: paid ?? this.paid,
    proof: clearProof ? null : (proof ?? this.proof),
    refund: clearRefund ? null : (refund ?? this.refund),
    paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    cancelledAt: clearCancelledAt ? null : (cancelledAt ?? this.cancelledAt),
  );
}

/// Status pengembalian uang (K24 Pembatalan dan pengembalian).
enum RefundStatus {
  /// Pengurus perlu mentransfer balik, lalu menandainya.
  perlu,

  /// Member batal mendadak dan mengajukan pengembalian; menunggu pengurus.
  diajukan,

  /// Batal mendadak tanpa pengajuan, atau pengajuannya ditolak.
  tidakKembali,

  /// Uang sudah ditransfer balik.
  selesai,
}

class Refund {
  const Refund({
    required this.status,
    required this.cancelledAt,
    this.reason,
    this.requested = false,
    this.rejected = false,
    this.doneAt,
  });

  final RefundStatus status;
  final DateTime cancelledAt;

  /// Alasan dari member saat mengajukan (sakit, keperluan mendadak, ...).
  final String? reason;

  /// Lewat pengajuan member (batal kurang dari batas waktu).
  final bool requested;

  /// Pengajuan ditolak pengurus.
  final bool rejected;
  final DateTime? doneAt;

  Refund copyWith({
    RefundStatus? status,
    String? reason,
    bool? requested,
    bool? rejected,
    DateTime? doneAt,
  }) => Refund(
    status: status ?? this.status,
    cancelledAt: cancelledAt,
    reason: reason ?? this.reason,
    requested: requested ?? this.requested,
    rejected: rejected ?? this.rejected,
    doneAt: doneAt ?? this.doneAt,
  );
}

/// Kapan dan bagaimana iuran dibayar (K22 Sistem iuran).
enum DuesTiming {
  sebelum('Sebelum main, harga tetap', 'Dibayar setelah konfirmasi ikut.'),
  setelahTetap('Setelah main, harga tetap', 'Ditagih ke yang hadir.'),
  perOrang('Setelah main, dihitung per orang', 'Match, kok, atau lapangan.');

  const DuesTiming(this.label, this.hint);
  final String label;
  final String hint;
}

/// Cara mencatat pemakaian untuk iuran per orang (K22b).
enum UsageMode {
  perOrang('Per orang'),
  perMatch('Per match');

  const UsageMode(this.label);
  final String label;
}

/// Aturan iuran satu PB.
class DuesSystem {
  const DuesSystem({
    this.timing = DuesTiming.sebelum,
    this.cancelHours = 24,
    this.remindUnpaid = true,
    this.autoBill = true,
    this.usageMode = UsageMode.perOrang,
    this.matchPrice = 10000,
    this.shuttlePrice = 4000,
    this.courtPrice = 100000,
    this.courtCapacity = 8,
    this.minCourts = 1,
    this.maxCourts = 2,
  });

  final DuesTiming timing;

  /// Batal paling lambat sekian jam sebelum sesi supaya uang kembali.
  final int cancelHours;

  /// Pengingat otomatis H-1 (sebelum main) atau H+1 (setelah main).
  final bool remindUnpaid;

  /// Setelah main harga tetap: tagihan terkirim otomatis saat kehadiran disimpan.
  final bool autoBill;
  final UsageMode usageMode;
  final int matchPrice;
  final int shuttlePrice;
  final int courtPrice;
  final int courtCapacity;
  final int minCourts;
  final int maxCourts;

  bool get afterPlay => timing != DuesTiming.sebelum;

  int billFor(Usage u) => u.matches * matchPrice + u.shuttles * shuttlePrice;

  /// Kisaran biaya lapangan per orang yang dilihat pemain (P8k): paling
  /// murah saat lapangan penuh, paling mahal saat lapangan tambahan baru
  /// terisi satu orang.
  (int, int) get courtShareRange {
    final low = courtPrice ~/ courtCapacity;
    if (maxCourts <= minCourts) return (low, low);
    final high =
        courtPrice * maxCourts ~/ (courtCapacity * (maxCourts - 1) + 1);
    return (low, high);
  }

  DuesSystem copyWith({
    DuesTiming? timing,
    int? cancelHours,
    bool? remindUnpaid,
    bool? autoBill,
    UsageMode? usageMode,
    int? matchPrice,
    int? shuttlePrice,
    int? courtPrice,
    int? courtCapacity,
    int? minCourts,
    int? maxCourts,
  }) => DuesSystem(
    timing: timing ?? this.timing,
    cancelHours: cancelHours ?? this.cancelHours,
    remindUnpaid: remindUnpaid ?? this.remindUnpaid,
    autoBill: autoBill ?? this.autoBill,
    usageMode: usageMode ?? this.usageMode,
    matchPrice: matchPrice ?? this.matchPrice,
    shuttlePrice: shuttlePrice ?? this.shuttlePrice,
    courtPrice: courtPrice ?? this.courtPrice,
    courtCapacity: courtCapacity ?? this.courtCapacity,
    minCourts: minCourts ?? this.minCourts,
    maxCourts: maxCourts ?? this.maxCourts,
  );
}

extension DuesSystemLabel on DuesSystem {
  /// Ringkasan satu baris untuk menu Akun pengurus.
  String summary(int fee) => switch (timing) {
    DuesTiming.sebelum => 'Sebelum main · ${_rp(fee)}',
    DuesTiming.setelahTetap => 'Setelah main · ${_rp(fee)}',
    DuesTiming.perOrang =>
      'Per orang · ${_rp(matchPrice)}/match · ${_rp(shuttlePrice)}/kok',
  };

  /// Penjelasan cara bayar untuk pemain (bagian "Cara bayar").
  String explain(int fee) => switch (timing) {
    DuesTiming.sebelum =>
      '${_rp(fee)} per sesi. Batal ≥$cancelHours jam sebelumnya, uang kembali.',
    DuesTiming.setelahTetap =>
      '${_rp(fee)} per sesi, ditagih setelah kamu dicatat hadir.',
    DuesTiming.perOrang =>
      '${_rp(matchPrice)} per match dan ${_rp(shuttlePrice)} per kok, ditagih setelah main.',
  };

  String get timingShort => switch (timing) {
    DuesTiming.sebelum => 'Sebelum main',
    DuesTiming.setelahTetap => 'Setelah main',
    DuesTiming.perOrang => 'Setelah main, per orang',
  };
}

String _rp(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return 'Rp$b';
}

/// Pemakaian satu pemain di satu sesi (iuran per orang).
class Usage {
  const Usage({this.matches = 0, this.shuttles = 0});

  final int matches;
  final int shuttles;

  Usage copyWith({int? matches, int? shuttles}) => Usage(
    matches: matches ?? this.matches,
    shuttles: shuttles ?? this.shuttles,
  );
}

/// Satu match di mode "per match": empat pemain dan kok yang dipakai.
class MatchRecord {
  const MatchRecord({
    required this.court,
    required this.players,
    this.shuttles = 1,
  });

  final int court;
  final List<String> players;
  final int shuttles;
}

/// Satu pertemuan PB pada tanggal tertentu.
class SessionEvent {
  const SessionEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.durationMinutes,
    required this.venue,
    this.attendees = const {},
    this.dues = const {},
    this.attendanceSaved = false,
    this.rsvps = const {},
    this.courts = 2,
    this.usage = const {},
    this.matches = const [],
    this.billsSent = false,
  });

  final String id;
  final String title;
  final DateTime start;
  final int durationMinutes;
  final String venue;

  /// Id member yang hadir.
  final Set<String> attendees;

  /// Iuran per id member. Dibuat saat kehadiran disimpan.
  final Map<String, Due> dues;
  final bool attendanceSaved;

  /// Konfirmasi ikut atau tidak per id member.
  final Map<String, Rsvp> rsvps;

  /// Jumlah lapangan yang dipakai.
  final int courts;

  /// Pemakaian per id member (iuran per orang).
  final Map<String, Usage> usage;

  /// Daftar match (iuran per orang, mode per match).
  final List<MatchRecord> matches;

  /// Tagihan per orang sudah dikirim ke pemain.
  final bool billsSent;

  /// Iuran yang sedang dalam urusan pengembalian.
  Iterable<MapEntry<String, Due>> get refunds =>
      dues.entries.where((d) => d.value.refund != null);

  /// Yang hadir tapi belum punya tagihan, misalnya saat tagihan otomatis mati.
  Iterable<String> get unbilledAttendees => attendees.where((id) {
    final due = dues[id];
    return due == null || due.refund?.status == RefundStatus.selesai;
  });

  /// Pemakaian yang boleh ditagih. Setelah kehadiran dicatat, hanya milik yang
  /// hadir.
  Iterable<MapEntry<String, Usage>> get chargeableUsage =>
      usage.entries.where((u) => !attendanceSaved || attendees.contains(u.key));

  int get goingCount => rsvps.values.where((r) => r == Rsvp.ikut).length;
  int get notGoingCount => rsvps.values.where((r) => r == Rsvp.tidak).length;

  /// Jumlah bukti transfer yang belum dicek pengurus.
  int get proofsToCheck => dues.values.where((d) => d.awaitingCheck).length;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  String get timeRange => '${_hm(start)}–${_hm(end)}';
  String get shortLabel => '${dayShort[start.weekday]} ${_hm(start)}';

  /// Iuran yang masih berlaku.
  Iterable<Due> get _active => dues.values.where((d) => d.billable);

  /// Uang yang jadi milik PB, termasuk batal mendadak yang tidak dikembalikan.
  int get collected => dues.values
      .where(
        (d) =>
            d.paid &&
            (d.refund == null || d.refund!.status == RefundStatus.tidakKembali),
      )
      .fold(0, (sum, d) => sum + d.amount);
  int get outstanding =>
      _active.where((d) => !d.paid).fold(0, (sum, d) => sum + d.amount);
  int get unpaidCount => _active.where((d) => !d.paid).length;

  /// Belum lunas dan belum mengirim bukti: yang perlu diingatkan.
  int get remindableCount =>
      _active.where((d) => !d.paid && !d.awaitingCheck).length;

  /// Konfirmasi ikut. Kalau iuran dibayar sebelum main, tagihan dibuat saat
  /// itu juga.
  SessionEvent confirm(String memberId, DuesSystem sys, int fee) {
    final dues = {...this.dues};
    final old = dues[memberId];
    final before = sys.timing == DuesTiming.sebelum;
    if (old == null) {
      if (before) dues[memberId] = Due(amount: fee);
    } else if (old.refund?.status == RefundStatus.selesai && !before) {
      // Uangnya sudah kembali; tagihan baru dibuat setelah main.
      dues.remove(memberId);
    } else {
      dues[memberId] = rejoin(old, fee);
    }
    return copyWith(rsvps: {...rsvps, memberId: Rsvp.ikut}, dues: dues);
  }

  /// Iuran member yang batal lalu ikut lagi. Kalau uangnya sudah dikembalikan,
  /// ditagih dari awal. Kalau belum, uang masih di pengurus, jadi urusan
  /// pengembaliannya dibatalkan.
  static Due rejoin(Due old, int fee) =>
      old.refund?.status == RefundStatus.selesai
      ? Due(amount: fee)
      : old.copyWith(clearRefund: true, clearCancelledAt: true);

  /// Batal ikut. Belum bayar: tagihan dihapus, kecuali bukti transfernya masih
  /// menunggu dicek. Sudah bayar: uang kembali kalau batal paling lambat
  /// [DuesSystem.cancelHours] jam sebelumnya, kalau lebih mepet tidak kembali
  /// kecuali member mengajukan. Pengembalian yang sudah berjalan tidak diubah.
  SessionEvent cancel(String memberId, DateTime now, DuesSystem sys) {
    final dues = {...this.dues};
    final due = dues[memberId];
    if (due != null && due.refund == null) {
      if (due.paid) {
        dues[memberId] = due.copyWith(refund: _refundAt(now, sys));
      } else if (due.awaitingCheck) {
        dues[memberId] = due.copyWith(cancelledAt: now);
      } else if (due.cancelledAt == null) {
        dues.remove(memberId);
      }
    }
    return copyWith(rsvps: {...rsvps, memberId: Rsvp.tidak}, dues: dues);
  }

  /// Menyesuaikan pengembalian setelah status bayar member yang sudah batal
  /// berubah: begitu dinyatakan lunas, uangnya ikut aturan pembatalan.
  Due settleCancelled(Due due, DuesSystem sys) {
    final at = due.cancelledAt;
    if (at == null) return due;
    if (!due.paid) return due.copyWith(clearRefund: true);
    if (due.refund != null) return due;
    return due.copyWith(refund: _refundAt(at, sys));
  }

  Refund _refundAt(DateTime cancelledAt, DuesSystem sys) => Refund(
    status: start.difference(cancelledAt).inMinutes >= sys.cancelHours * 60
        ? RefundStatus.perlu
        : RefundStatus.tidakKembali,
    cancelledAt: cancelledAt,
  );

  /// Batal mendadak tapi member mengajukan pengembalian dengan alasan. Hanya
  /// berlaku untuk uang yang belum kembali dan belum diproses.
  SessionEvent requestRefund(String memberId, String reason) {
    if (dues[memberId]?.refund?.status != RefundStatus.tidakKembali) {
      return this;
    }
    return _withRefund(
      memberId,
      (r) => r.copyWith(
        status: RefundStatus.diajukan,
        reason: reason,
        requested: true,
      ),
    );
  }

  /// Pengurus menyetujui atau menolak pengajuan pengembalian.
  SessionEvent decideRefund(String memberId, {required bool approve}) =>
      _withRefund(
        memberId,
        (r) => r.copyWith(
          status: approve ? RefundStatus.perlu : RefundStatus.tidakKembali,
          rejected: !approve,
        ),
      );

  /// Pengurus sudah mentransfer balik uangnya.
  SessionEvent markRefunded(String memberId, DateTime now) => _withRefund(
    memberId,
    (r) => r.copyWith(status: RefundStatus.selesai, doneAt: now),
  );

  /// Mengembalikan status pengembalian, untuk tombol "Batalkan".
  SessionEvent setRefundStatus(String memberId, RefundStatus status) =>
      _withRefund(
        memberId,
        (r) => Refund(
          status: status,
          cancelledAt: r.cancelledAt,
          reason: r.reason,
          requested: r.requested,
        ),
      );

  SessionEvent _withRefund(String memberId, Refund Function(Refund) change) {
    final due = dues[memberId];
    final refund = due?.refund;
    if (due == null || refund == null) return this;
    return copyWith(
      dues: {
        ...dues,
        memberId: due.copyWith(refund: change(refund)),
      },
    );
  }

  /// Menghitung pemakaian per pemain dari daftar match.
  static Map<String, Usage> usageFromMatches(List<MatchRecord> matches) {
    final out = <String, Usage>{};
    for (final m in matches) {
      for (final p in m.players) {
        final u = out[p] ?? const Usage();
        out[p] = Usage(matches: u.matches + 1, shuttles: u.shuttles);
      }
      // Kok dibagi rata; sisa pembagian dibebankan ke pemain pertama.
      if (m.players.isEmpty) continue;
      final each = m.shuttles ~/ m.players.length;
      final rest = m.shuttles % m.players.length;
      for (final (i, p) in m.players.indexed) {
        final u = out[p]!;
        out[p] = u.copyWith(shuttles: u.shuttles + each + (i < rest ? 1 : 0));
      }
    }
    return out;
  }

  /// "19.00"
  static String hmOf(DateTime t) => _hm(t);

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  SessionEvent copyWith({
    Set<String>? attendees,
    Map<String, Due>? dues,
    bool? attendanceSaved,
    Map<String, Rsvp>? rsvps,
    int? courts,
    Map<String, Usage>? usage,
    List<MatchRecord>? matches,
    bool? billsSent,
  }) => SessionEvent(
    id: id,
    title: title,
    start: start,
    durationMinutes: durationMinutes,
    venue: venue,
    attendees: attendees ?? this.attendees,
    dues: dues ?? this.dues,
    attendanceSaved: attendanceSaved ?? this.attendanceSaved,
    rsvps: rsvps ?? this.rsvps,
    courts: courts ?? this.courts,
    usage: usage ?? this.usage,
    matches: matches ?? this.matches,
    billsSent: billsSent ?? this.billsSent,
  );
}

enum CoManagerStatus { diundang, aktif }

/// Pengurus lain yang ikut mengelola PB bersama pemilik.
class CoManager {
  const CoManager({
    required this.id,
    required this.name,
    required this.whatsapp,
    this.status = CoManagerStatus.diundang,
  });

  final String id;
  final String name;

  /// Nomor ternormalisasi (62...).
  final String whatsapp;
  final CoManagerStatus status;

  String get initials => initialsOf(name);
}

/// Semua data PB yang dikelola pengguna.
class ManageState {
  const ManageState({
    this.pb,
    this.members = const [],
    this.events = const [],
    this.coManagers = const [],
    this.duesSystem = const DuesSystem(),
  });

  /// Aturan iuran PB (K22).
  final DuesSystem duesSystem;

  /// Null berarti pengguna belum mendaftarkan PB.
  final Pb? pb;
  final List<Member> members;
  final List<SessionEvent> events;

  /// Pengurus selain pemilik. Pemilik adalah pengguna yang mendaftarkan PB.
  final List<CoManager> coManagers;

  /// Bukti transfer yang menunggu dicek, di semua sesi.
  int get proofsToCheck => events.fold(0, (sum, e) => sum + e.proofsToCheck);

  bool get hasPb => pb != null;

  Member? memberById(String id) => members.where((m) => m.id == id).firstOrNull;
  SessionEvent? eventById(String id) =>
      events.where((e) => e.id == id).firstOrNull;

  /// Sesi yang belum lewat, dari yang paling dekat.
  List<SessionEvent> upcoming(DateTime now) =>
      events.where((e) => e.end.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// Sesi yang sudah lewat, dari yang terbaru.
  List<SessionEvent> past(DateTime now) =>
      events.where((e) => !e.end.isAfter(now)).toList()
        ..sort((a, b) => b.start.compareTo(a.start));

  /// Sesi terakhir yang kehadirannya sudah dicatat.
  SessionEvent? get lastRecorded {
    final recorded = events.where((e) => e.attendanceSaved).toList()
      ..sort((a, b) => b.start.compareTo(a.start));
    return recorded.firstOrNull;
  }

  /// Persentase iuran yang sudah lunas dari semua sesi, atau null kalau
  /// belum ada iuran tercatat.
  int? get paidPercent {
    final all = events
        .expand((e) => e.dues.values)
        .where((d) => d.billable || d.refund != null)
        .toList();
    if (all.isEmpty) return null;
    return (all.where((d) => d.paid).length * 100 / all.length).round();
  }

  ManageState copyWith({
    Pb? pb,
    List<Member>? members,
    List<SessionEvent>? events,
    List<CoManager>? coManagers,
    DuesSystem? duesSystem,
  }) => ManageState(
    pb: pb ?? this.pb,
    members: members ?? this.members,
    events: events ?? this.events,
    coManagers: coManagers ?? this.coManagers,
    duesSystem: duesSystem ?? this.duesSystem,
  );

  /// Semua iuran yang sedang dalam urusan pengembalian, dari semua sesi.
  List<(SessionEvent, String, Due)> get refunds => [
    for (final e in events)
      for (final d in e.refunds) (e, d.key, d.value),
  ];

  /// Pengembalian yang perlu ditindak pengurus (transfer balik atau putuskan).
  int get refundsToHandle => refunds
      .where(
        (r) =>
            r.$3.refund!.status == RefundStatus.perlu ||
            r.$3.refund!.status == RefundStatus.diajukan,
      )
      .length;
}

/// Satu baris hasil impor catatan yang menunggu konfirmasi pengurus.
class ImportRow {
  const ImportRow({
    required this.name,
    required this.type,
    this.amount,
    this.paid,
    this.needsReview = false,
    this.reason,
    this.source = '',
  });

  final String name;
  final MemberType type;
  final int? amount;

  /// Null berarti status bayar tidak tertulis di catatan.
  final bool? paid;
  final bool needsReview;
  final String? reason;

  /// Baris asli dari catatan, untuk dibandingkan pengurus.
  final String source;

  ImportRow copyWith({
    String? name,
    MemberType? type,
    bool? needsReview,
    bool clearReason = false,
  }) => ImportRow(
    name: name ?? this.name,
    type: type ?? this.type,
    amount: amount,
    paid: paid,
    needsReview: needsReview ?? this.needsReview,
    reason: clearReason ? null : reason,
    source: source,
  );
}
