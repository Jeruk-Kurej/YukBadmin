import '../../pb/data/pb_codec.dart';
import '../../pb/data/pb_models.dart';
import 'manage_models.dart';

/// Konversi data pengurus ke dan dari JSON untuk cache lokal.

Map<String, Object?> manageStateToJson(ManageState s) => {
  'pb': s.pb == null ? null : pbToJson(s.pb!),
  'members': [for (final m in s.members) memberToJson(m)],
  'events': [for (final e in s.events) eventToJson(e)],
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
  );
}

Map<String, Object?> _dueToJson(Due d) => {
  'amount': d.amount,
  'paid': d.paid,
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
  return Due(
    amount: m['amount']! as int,
    paid: m['paid']! as bool,
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
