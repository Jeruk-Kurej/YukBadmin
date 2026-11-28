import 'package:supabase_flutter/supabase_flutter.dart';

import 'pb_models.dart';
import 'pb_repository.dart';

/// Daftar PB dari tabel `pbs` dan `pb_sessions` di Supabase. Bisa dibaca
/// tanpa masuk (RLS mengizinkan baca untuk semua).
class SupabasePbRepository implements PbRepository {
  const SupabasePbRepository(this.client);
  final SupabaseClient client;

  @override
  Future<List<Pb>> fetchAll() async {
    final rows = await client
        .from('pbs')
        .select('*, pb_sessions(*)')
        .order('name');
    return [for (final row in rows) pbFromRow(row)];
  }
}

/// Satu baris `pbs` (beserta `pb_sessions`) ke model [Pb].
Pb pbFromRow(Map<String, dynamic> r) {
  final sessions =
      [
        for (final s in (r['pb_sessions'] as List? ?? const []))
          _sessionFromRow(s as Map<String, dynamic>),
      ]..sort(
        (a, b) => a.weekday != b.weekday
            ? a.weekday.compareTo(b.weekday)
            : a.startHour.compareTo(b.startHour),
      );
  return Pb(
    id: r['id'] as String,
    name: r['name'] as String,
    venue: r['venue'] as String,
    district: r['district'] as String,
    area: r['area'] as String,
    memberCount: r['member_count'] as int,
    quota: r['quota'] as int,
    minLevel: Level.values.byName(r['min_level'] as String),
    maxLevel: Level.values.byName(r['max_level'] as String),
    memberTypes: {
      for (final t in r['member_types'] as List)
        MemberType.values.byName(t as String),
    },
    feePerSession: r['fee_per_session'] as int,
    monthlyFee: r['monthly_fee'] as int?,
    sessions: sessions,
    about: r['about'] as String? ?? '',
    rules: [for (final x in (r['rules'] as List? ?? const [])) x as String],
    manager: PbManager(
      name: r['manager_name'] as String,
      whatsapp: r['manager_whatsapp'] as String,
    ),
    openForNewMembers: r['open_for_new_members'] as bool,
    artSeed: r['art_seed'] as int? ?? 0,
    latitude: (r['latitude'] as num?)?.toDouble(),
    longitude: (r['longitude'] as num?)?.toDouble(),
    foundedYear: r['founded_year'] as int?,
    levelTest: r['level_test'] as bool? ?? false,
    logoPath: r['logo_url'] as String?,
    photoPaths: [
      for (final x in (r['photo_urls'] as List? ?? const [])) x as String,
    ],
  );
}

PbSession _sessionFromRow(Map<String, dynamic> s) {
  final (sh, sm) = _time(s['start_time'] as String);
  final (eh, em) = _time(s['end_time'] as String);
  return PbSession(
    weekday: s['weekday'] as int,
    startHour: sh,
    startMinute: sm,
    endHour: eh,
    endMinute: em,
    venue: s['venue'] as String,
  );
}

/// "19:00:00" ke (19, 0).
(int, int) _time(String t) {
  final p = t.split(':');
  return (int.parse(p[0]), int.parse(p[1]));
}
