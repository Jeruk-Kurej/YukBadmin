import '../../pb/data/pb_codec.dart';
import '../../pb/data/pb_models.dart';
import 'manage_models.dart';

/// Konversi data pengurus ke dan dari JSON untuk cache lokal.

Map<String, Object?> manageStateToJson(ManageState s) => {
  'pb': s.pb == null ? null : pbToJson(s.pb!),
  'members': [for (final m in s.members) memberToJson(m)],
  'events': [for (final e in s.events) eventToJson(e)],
  'duesSystem': duesSystemToJson(s.duesSystem),
  'coManagers': [
    for (final c in s.coManagers)
      {
        'id': c.id,
        'name': c.name,
        'whatsapp': c.whatsapp,
        'status': c.status.name,
      },
  ],
};

ManageState manageStateFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  return ManageState(
    pb: m['pb'] == null ? null : pbFromJson(m['pb']),
    members: [for (final x in m['members']! as List) memberFromJson(x)],
    events: [for (final x in m['events']! as List) eventFromJson(x)],
    duesSystem: m['duesSystem'] == null
        ? const DuesSystem()
        : duesSystemFromJson(m['duesSystem']),
    coManagers: [
      for (final x in (m['coManagers'] as List?) ?? [])
        if (x case final Map<String, Object?> c)
          CoManager(
            id: c['id']! as String,
            name: c['name']! as String,
            whatsapp: c['whatsapp']! as String,
            status: CoManagerStatus.values.byName(c['status']! as String),
          ),
    ],
  );
}

Map<String, Object?> memberToJson(Member m) => {
  'id': m.id,
  'name': m.name,
  'type': m.type.name,
  'level': m.level?.name,
  'whatsapp': m.whatsapp,
  'photoPath': m.photoPath,
};

Member memberFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  final level = m['level'] as String?;
  return Member(
    id: m['id']! as String,
    name: m['name']! as String,
    type: MemberType.values.byName(m['type']! as String),
    level: level == null ? null : Level.values.byName(level),
    whatsapp: m['whatsapp'] as String?,
    photoPath: m['photoPath'] as String?,
  );
}

Map<String, Object?> eventToJson(SessionEvent e) => {
  'id': e.id,
  'title': e.title,
  'start': e.start.toIso8601String(),
  'durationMinutes': e.durationMinutes,
  'venue': e.venue,
  'attendees': e.attendees.toList(),
  'dues': {for (final d in e.dues.entries) d.key: _dueToJson(d.value)},
  'attendanceSaved': e.attendanceSaved,
  'rsvps': {for (final r in e.rsvps.entries) r.key: r.value.name},
  'courts': e.courts,
  'usage': {
    for (final u in e.usage.entries)
      u.key: {'matches': u.value.matches, 'shuttles': u.value.shuttles},
  },
  'matches': [
    for (final x in e.matches)
      {'court': x.court, 'players': x.players, 'shuttles': x.shuttles},
  ],
  'billsSent': e.billsSent,
};

SessionEvent eventFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  return SessionEvent(
    id: m['id']! as String,
    title: m['title']! as String,
    start: DateTime.parse(m['start']! as String),
    durationMinutes: m['durationMinutes']! as int,
    venue: m['venue']! as String,
    attendees: {for (final a in m['attendees']! as List) a as String},
    dues: {
      for (final d in (m['dues']! as Map<String, Object?>).entries)
        d.key: _dueFromJson(d.value),
    },
    attendanceSaved: m['attendanceSaved']! as bool,
    rsvps: {
      for (final r in ((m['rsvps'] as Map<String, Object?>?) ?? {}).entries)
        r.key: Rsvp.values.byName(r.value! as String),
    },
    courts: (m['courts'] as int?) ?? 2,
    usage: {
      for (final u in ((m['usage'] as Map<String, Object?>?) ?? {}).entries)
        if (u.value case final Map<String, Object?> v)
          u.key: Usage(
            matches: v['matches']! as int,
            shuttles: v['shuttles']! as int,
          ),
    },
    matches: [
      for (final x in (m['matches'] as List?) ?? [])
        if (x case final Map<String, Object?> v)
          MatchRecord(
            court: v['court']! as int,
            players: [for (final p in v['players']! as List) p as String],
            shuttles: v['shuttles']! as int,
          ),
    ],
    billsSent: (m['billsSent'] as bool?) ?? false,
  );
}

Map<String, Object?> duesSystemToJson(DuesSystem d) => {
  'timing': d.timing.name,
  'cancelHours': d.cancelHours,
  'remindUnpaid': d.remindUnpaid,
  'autoBill': d.autoBill,
  'usageMode': d.usageMode.name,
  'matchPrice': d.matchPrice,
  'shuttlePrice': d.shuttlePrice,
  'courtPrice': d.courtPrice,
  'courtCapacity': d.courtCapacity,
  'minCourts': d.minCourts,
  'maxCourts': d.maxCourts,
};

DuesSystem duesSystemFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  return DuesSystem(
    timing: DuesTiming.values.byName(m['timing']! as String),
    cancelHours: m['cancelHours']! as int,
    remindUnpaid: m['remindUnpaid']! as bool,
    autoBill: m['autoBill']! as bool,
    usageMode: UsageMode.values.byName(m['usageMode']! as String),
    matchPrice: m['matchPrice']! as int,
    shuttlePrice: m['shuttlePrice']! as int,
    courtPrice: m['courtPrice']! as int,
    courtCapacity: m['courtCapacity']! as int,
    minCourts: m['minCourts']! as int,
    maxCourts: m['maxCourts']! as int,
  );
}

Map<String, Object?> _dueToJson(Due d) => {
  'amount': d.amount,
  'paid': d.paid,
  'paidAt': d.paidAt?.toIso8601String(),
  'cancelledAt': d.cancelledAt?.toIso8601String(),
  if (d.refund case final r?)
    'refund': {
      'status': r.status.name,
      'cancelledAt': r.cancelledAt.toIso8601String(),
      'reason': r.reason,
      'requested': r.requested,
      'rejected': r.rejected,
      'doneAt': r.doneAt?.toIso8601String(),
    },
  if (d.proof case final p?)
    'proof': {
      'path': p.path,
      'sentAt': p.sentAt.toIso8601String(),
      'status': p.status.name,
      'reason': p.reason,
    },
};

Due _dueFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  final p = m['proof'] as Map<String, Object?>?;
  final r = m['refund'] as Map<String, Object?>?;
  final paidAt = m['paidAt'] as String?;
  final cancelledAt = m['cancelledAt'] as String?;
  return Due(
    amount: m['amount']! as int,
    paid: m['paid']! as bool,
    paidAt: paidAt == null ? null : DateTime.parse(paidAt),
    cancelledAt: cancelledAt == null ? null : DateTime.parse(cancelledAt),
    refund: r == null
        ? null
        : Refund(
            status: RefundStatus.values.byName(r['status']! as String),
            cancelledAt: DateTime.parse(r['cancelledAt']! as String),
            reason: r['reason'] as String?,
            requested: (r['requested'] as bool?) ?? false,
            rejected: (r['rejected'] as bool?) ?? false,
            doneAt: r['doneAt'] == null
                ? null
                : DateTime.parse(r['doneAt']! as String),
          ),
    proof: p == null
        ? null
        : PaymentProof(
            path: p['path']! as String,
            sentAt: DateTime.parse(p['sentAt']! as String),
            status: ProofStatus.values.byName(p['status']! as String),
            reason: p['reason'] as String?,
          ),
  );
}
