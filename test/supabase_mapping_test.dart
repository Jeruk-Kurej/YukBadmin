import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yukbadmin/core/data/supabase_config.dart';
import 'package:yukbadmin/features/auth/state/auth_providers.dart';
import 'package:yukbadmin/features/gear/data/gear_models.dart';
import 'package:yukbadmin/features/gear/data/supabase_gear_repository.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/supabase_pb_repository.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';

/// Bentuk baris seperti yang dikirim Supabase untuk `pbs` + `pb_sessions`.
Map<String, dynamic> _pbRow() => {
  'id': 'pb-uji',
  'owner_id': null,
  'name': 'PB Uji',
  'venue': 'GOR Uji',
  'district': 'Gubeng',
  'area': 'Surabaya Timur',
  'member_count': 12,
  'quota': 30,
  'min_level': 'd',
  'max_level': 'b',
  'member_types': ['tetap', 'insidental'],
  'fee_per_session': 150000,
  'monthly_fee': null,
  'about': 'PB santai.',
  'rules': ['Bawa raket sendiri'],
  'manager_name': 'Pak Hendra',
  'manager_whatsapp': '6281311112222',
  'open_for_new_members': true,
  'art_seed': 2,
  'latitude': -7.28,
  'longitude': 112.76,
  'founded_year': 2019,
  'level_test': false,
  'logo_url': null,
  'photo_urls': <String>[],
  'pb_sessions': [
    {
      'weekday': 6,
      'start_time': '08:00:00',
      'end_time': '11:00:00',
      'venue': 'GOR Uji',
    },
    {
      'weekday': 3,
      'start_time': '19:30:00',
      'end_time': '22:00:00',
      'venue': 'GOR Uji',
    },
  ],
};

void main() {
  test('tanpa dart-define, app memakai data lokal', () {
    expect(SupabaseConfig.isConfigured, isFalse);
  });

  test('baris pbs dan pb_sessions menjadi model Pb', () {
    final pb = pbFromRow(_pbRow());
    expect(pb.id, 'pb-uji');
    expect(pb.memberCount, 12);
    expect(pb.minLevel, Level.d);
    expect(pb.memberTypes, {MemberType.tetap, MemberType.insidental});
    expect(pb.monthlyFee, isNull);
    // Jadwal diurutkan per hari, jam dibaca dari kolom time.
    expect(pb.sessions.first.weekday, 3);
    expect(pb.sessions.first.timeRange, '19.30–22.00');
    expect(pb.sessions.last.dayName, 'Sabtu');
    expect(pb.levelRange, 'D–B');
  });

  test('baris products menjadi model Product, termasuk spesifikasi raket', () {
    final p = productFromRow({
      'id': 'produk-1',
      'shop_id': 'toko-gesit',
      'name': 'Raket Uji',
      'category': 'raket',
      'price': 500000,
      'in_stock': false,
      'description': '',
      'racket_weight': 'u4',
      'racket_balance': 'even',
      'racket_flex': 'medium',
      'shoe_sizes': <int>[],
      'string_type': null,
      'photo_url': null,
    });
    expect(p.category, GearCategory.raket);
    expect(p.inStock, isFalse);
    expect(p.racket?.weight, RacketWeight.u4);
    expect(p.stringType, isNull);
  });

  test('galat Supabase Auth diterjemahkan ke pesan yang jelas', () {
    AuthError map(String code, [String status = '400']) =>
        authErrorFromSupabase(
          AuthException('x', code: code, statusCode: status),
        );
    expect(map('user_already_exists'), AuthError.emailTaken);
    expect(map('email_exists'), AuthError.emailTaken);
    expect(map('invalid_credentials'), AuthError.invalidCredentials);
    expect(map('email_not_confirmed'), AuthError.emailNotConfirmed);
    expect(map('weak_password'), AuthError.weakPassword);
    expect(map('apa_saja', '429'), AuthError.tooManyAttempts);
    expect(map('apa_saja'), AuthError.unknown);
    // Galat yang muncul di bawah kolom, sisanya lewat pesan singkat.
    expect(AuthError.invalidCredentials.onPassword, isTrue);
    expect(AuthError.emailNotConfirmed.onEmail, isTrue);
    expect(AuthError.network.onEmail || AuthError.network.onPassword, isFalse);
  });

  test('preferensi bolak-balik ke kolom profiles', () {
    const prefs = PlayerPreferences(
      level: Level.c,
      area: 'Surabaya Barat',
      weekdays: {6, 3},
    );
    final row = preferencesToProfile(prefs);
    expect(row['weekdays'], [3, 6]);
    final back = profileToPreferences({...row, 'prefs_done': true});
    expect(back.level, Level.c);
    expect(back.area, 'Surabaya Barat');
    expect(back.weekdays, {3, 6});
    expect(profileToPreferences({'level': null}).level, isNull);
  });

  test('pengguna Supabase menjadi SessionUser dengan status verifikasi', () {
    final user = User(
      id: 'u1',
      appMetadata: const {},
      userMetadata: const {'name': 'Sinta Dewi'},
      aud: 'authenticated',
      createdAt: '2026-11-27T00:00:00Z',
      email: 'sinta@contoh.id',
    );
    final s = sessionUserFromSupabase(user)!;
    expect(s.name, 'Sinta Dewi');
    expect(s.emailVerified, isFalse);
    expect(sessionUserFromSupabase(null), isNull);
  });
}
