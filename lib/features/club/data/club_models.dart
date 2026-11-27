import '../../manage/data/manage_codec.dart';
import '../../manage/data/manage_models.dart';
import '../../pb/data/pb_models.dart';

/// Keanggotaan pengguna di satu PB: yang dilihat member di "PB-ku".
/// Jadwal dan iuran di sini hanya milik member itu; jumlah yang ikut boleh
/// terlihat, nama member lain tidak (keputusan privasi).
class Membership {
  const Membership({
    required this.pbId,
    required this.memberId,
    required this.type,
    this.events = const [],
    this.fee = 0,
    this.duesSystem = const DuesSystem(),
  });

  final String pbId;

  /// Biaya per sesi PB ini.
  final int fee;

  /// Aturan iuran PB ini (cara bayar dan batas pembatalan).
  final DuesSystem duesSystem;

  /// Id member di catatan pengurus.
  final String memberId;
  final MemberType type;
  final List<SessionEvent> events;

  SessionEvent? eventById(String id) =>
      events.where((e) => e.id == id).firstOrNull;

  Membership copyWith({List<SessionEvent>? events}) => Membership(
    pbId: pbId,
    memberId: memberId,
    type: type,
    events: events ?? this.events,
    fee: fee,
    duesSystem: duesSystem,
  );
}

/// Ringkasan yang dipakai kartu PB-ku dan beranda.
extension MembershipSummary on Membership {
  /// Sesi mendatang, dari yang paling dekat.
  List<SessionEvent> upcoming(DateTime now) =>
      events.where((e) => e.end.isAfter(now)).toList()
        ..sort((a, b) => a.start.compareTo(b.start));

  /// Iuran milik member ini yang belum lunas.
  List<(SessionEvent, Due)> unpaidDues() => [
    for (final e in events)
      if (e.dues[memberId] case final due? when !due.paid && due.billable)
        (e, due),
  ];

  /// Sesi mendatang yang belum dijawab ikut atau tidak.
  int unansweredCount(DateTime now) =>
      upcoming(now)
          .where((e) => e.start.isAfter(now) && !e.rsvps.containsKey(memberId))
          .length;
}

Map<String, Object?> membershipToJson(Membership m) => {
  'pbId': m.pbId,
  'memberId': m.memberId,
  'type': m.type.name,
  'events': [for (final e in m.events) eventToJson(e)],
  'fee': m.fee,
  'duesSystem': duesSystemToJson(m.duesSystem),
};

Membership membershipFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  return Membership(
    pbId: m['pbId']! as String,
    memberId: m['memberId']! as String,
    type: MemberType.values.byName(m['type']! as String),
    events: [for (final e in m['events']! as List) eventFromJson(e)],
    fee: (m['fee'] as int?) ?? 0,
    duesSystem: m['duesSystem'] == null
        ? const DuesSystem()
        : duesSystemFromJson(m['duesSystem']),
  );
}
