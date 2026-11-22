import 'pb_models.dart';

/// Konversi model PB ke dan dari JSON untuk cache lokal. Bentuknya sengaja
/// mirip kolom tabel yang direncanakan di Supabase.

Map<String, Object?> pbToJson(Pb pb) => {
  'id': pb.id,
  'name': pb.name,
  'venue': pb.venue,
  'district': pb.district,
  'area': pb.area,
  'memberCount': pb.memberCount,
  'quota': pb.quota,
  'minLevel': pb.minLevel.name,
  'maxLevel': pb.maxLevel.name,
  'memberTypes': [for (final t in pb.memberTypes) t.name],
  'feePerSession': pb.feePerSession,
  'monthlyFee': pb.monthlyFee,
  'sessions': [for (final s in pb.sessions) _sessionToJson(s)],
  'about': pb.about,
  'rules': pb.rules,
  'manager': {'name': pb.manager.name, 'whatsapp': pb.manager.whatsapp},
  'openForNewMembers': pb.openForNewMembers,
  'artSeed': pb.artSeed,
  'latitude': pb.latitude,
  'longitude': pb.longitude,
  'foundedYear': pb.foundedYear,
  'levelTest': pb.levelTest,
  'logoPath': pb.logoPath,
  'photoPaths': pb.photoPaths,
  'paymentInfo': pb.paymentInfo,
};

Pb pbFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  final manager = m['manager']! as Map<String, Object?>;
  return Pb(
    id: m['id']! as String,
    name: m['name']! as String,
    venue: m['venue']! as String,
    district: m['district']! as String,
    area: m['area']! as String,
    memberCount: m['memberCount']! as int,
    quota: m['quota']! as int,
    minLevel: Level.values.byName(m['minLevel']! as String),
    maxLevel: Level.values.byName(m['maxLevel']! as String),
    memberTypes: {
      for (final t in m['memberTypes']! as List)
        MemberType.values.byName(t as String),
    },
    feePerSession: m['feePerSession']! as int,
    monthlyFee: m['monthlyFee'] as int?,
    sessions: [
      for (final s in m['sessions']! as List)
        _sessionFromJson(s as Map<String, Object?>),
    ],
    about: m['about']! as String,
    rules: [for (final r in m['rules']! as List) r as String],
    manager: PbManager(
      name: manager['name']! as String,
      whatsapp: manager['whatsapp']! as String,
    ),
    openForNewMembers: m['openForNewMembers']! as bool,
    artSeed: m['artSeed']! as int,
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    foundedYear: m['foundedYear'] as int?,
    levelTest: m['levelTest'] as bool? ?? false,
    logoPath: m['logoPath'] as String?,
    photoPaths: [for (final p in (m['photoPaths'] as List?) ?? []) p as String],
    paymentInfo: m['paymentInfo'] as String?,
  );
}

Map<String, Object?> _sessionToJson(PbSession s) => {
  'weekday': s.weekday,
  'startHour': s.startHour,
  'startMinute': s.startMinute,
  'endHour': s.endHour,
  'endMinute': s.endMinute,
  'venue': s.venue,
};

PbSession _sessionFromJson(Map<String, Object?> m) => PbSession(
  weekday: m['weekday']! as int,
  startHour: m['startHour']! as int,
  startMinute: m['startMinute']! as int,
  endHour: m['endHour']! as int,
  endMinute: m['endMinute']! as int,
  venue: m['venue']! as String,
);

Map<String, Object?> preferencesToJson(PlayerPreferences p) => {
  'level': p.level?.name,
  'area': p.area,
  'weekdays': p.weekdays.toList()..sort(),
};

PlayerPreferences preferencesFromJson(Object? json) {
  final m = json! as Map<String, Object?>;
  final level = m['level'] as String?;
  return PlayerPreferences(
    level: level == null ? null : Level.values.byName(level),
    area: m['area']! as String,
    weekdays: {for (final d in m['weekdays']! as List) d as int},
  );
}
