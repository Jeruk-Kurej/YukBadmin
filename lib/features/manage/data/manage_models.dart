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
  const Due({required this.amount, this.paid = false, this.proof});

  final int amount;
  final bool paid;

  /// Bukti transfer terakhir, kalau member mengirimnya.
  final PaymentProof? proof;

  /// Bukti sudah dikirim dan menunggu dicek pengurus.
  bool get awaitingCheck => !paid && proof?.status == ProofStatus.menunggu;

  Due copyWith({
    int? amount,
    bool? paid,
    PaymentProof? proof,
    bool clearProof = false,
  }) => Due(
    amount: amount ?? this.amount,
    paid: paid ?? this.paid,
    proof: clearProof ? null : (proof ?? this.proof),
  );
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

  int get goingCount => rsvps.values.where((r) => r == Rsvp.ikut).length;
  int get notGoingCount => rsvps.values.where((r) => r == Rsvp.tidak).length;

  /// Jumlah bukti transfer yang belum dicek pengurus.
  int get proofsToCheck => dues.values.where((d) => d.awaitingCheck).length;

  DateTime get end => start.add(Duration(minutes: durationMinutes));

  String get timeRange => '${_hm(start)}–${_hm(end)}';
  String get shortLabel => '${dayShort[start.weekday]} ${_hm(start)}';

  int get collected =>
      dues.values.where((d) => d.paid).fold(0, (sum, d) => sum + d.amount);
  int get outstanding =>
      dues.values.where((d) => !d.paid).fold(0, (sum, d) => sum + d.amount);
  int get unpaidCount => dues.values.where((d) => !d.paid).length;

  /// Belum lunas dan belum mengirim bukti: yang perlu diingatkan.
  int get remindableCount =>
      dues.values.where((d) => !d.paid && !d.awaitingCheck).length;

  static String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}.${t.minute.toString().padLeft(2, '0')}';

  SessionEvent copyWith({
    Set<String>? attendees,
    Map<String, Due>? dues,
    bool? attendanceSaved,
    Map<String, Rsvp>? rsvps,
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
  });

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
    final all = events.expand((e) => e.dues.values).toList();
    if (all.isEmpty) return null;
    return (all.where((d) => d.paid).length * 100 / all.length).round();
  }

  ManageState copyWith({
    Pb? pb,
    List<Member>? members,
    List<SessionEvent>? events,
    List<CoManager>? coManagers,
  }) => ManageState(
    pb: pb ?? this.pb,
    members: members ?? this.members,
    events: events ?? this.events,
    coManagers: coManagers ?? this.coManagers,
  );
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
