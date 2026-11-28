import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/data/local_store.dart';
import '../../../core/data/supabase_config.dart';
import '../../pb/data/pb_models.dart';
import '../../pb/state/providers.dart';
import '../data/local_accounts.dart';

/// Alasan daftar atau masuk ditolak.
enum AuthError {
  emailTaken('Email ini sudah terdaftar. Pilih Masuk, atau pakai email lain.'),
  notRegistered('Email ini belum terdaftar. Pilih Daftar untuk membuat akun.'),
  wrongPassword('Kata sandi salah. Cek lagi huruf besar dan kecilnya.'),

  /// Supabase sengaja tidak membedakan email belum terdaftar dan kata sandi
  /// salah, supaya orang lain tidak bisa menebak email siapa yang terdaftar.
  invalidCredentials(
    'Email atau kata sandi salah. Belum punya akun? Pilih Daftar.',
  ),
  emailNotConfirmed(
    'Email belum diverifikasi. Buka tautan yang kami kirim ke emailmu, lalu masuk lagi.',
  ),
  weakPassword(
    'Kata sandi terlalu mudah ditebak. Pakai minimal 8 karakter campuran huruf dan angka.',
  ),
  tooManyAttempts(
    'Terlalu banyak percobaan. Tunggu beberapa menit, lalu coba lagi.',
  ),
  network('Tidak tersambung ke server. Periksa internet, lalu coba lagi.'),
  unknown('Gagal memproses akun. Coba lagi sebentar lagi.');

  const AuthError(this.message);
  final String message;

  /// Galat yang ditampilkan di bawah kolom email.
  bool get onEmail =>
      this == emailTaken || this == notRegistered || this == emailNotConfirmed;

  /// Galat yang ditampilkan di bawah kolom kata sandi.
  bool get onPassword =>
      this == wrongPassword ||
      this == invalidCredentials ||
      this == weakPassword;
}

/// Hasil daftar atau masuk.
class AuthOutcome {
  const AuthOutcome.success({required this.preferencesDone})
    : error = null,
      needsVerification = false;
  const AuthOutcome.failed(AuthError this.error)
    : preferencesDone = false,
      needsVerification = false;

  /// Akun dibuat, tapi harus verifikasi email sebelum bisa masuk.
  const AuthOutcome.verifyEmail()
    : error = null,
      preferencesDone = false,
      needsVerification = true;

  final AuthError? error;
  final bool preferencesDone;
  final bool needsVerification;
}

/// Daftar, masuk, dan keluar. Layar Masuk hanya memakai antarmuka ini, jadi
/// akun lokal dan Supabase Auth bisa ditukar tanpa mengubah layar.
abstract interface class AuthService {
  Future<AuthOutcome> register({
    required String name,
    required String email,
    required String password,
  });
  Future<AuthOutcome> signIn({required String email, required String password});

  /// Halaman preferensi selesai (diisi atau dilewati): tidak muncul lagi.
  Future<void> completePreferences(PlayerPreferences prefs);
  Future<void> signOut();
}

/// Akun yang tersimpan di HP (dipakai saat Supabase belum dikonfigurasi dan
/// di tes).
class LocalAuthService implements AuthService {
  const LocalAuthService(this.ref);
  final Ref ref;

  AccountsNotifier get _accounts => ref.read(accountsProvider.notifier);

  @override
  Future<AuthOutcome> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final error = _accounts.register(
      name: name,
      email: email,
      password: password,
    );
    return error == null
        ? AuthOutcome.success(preferencesDone: _accounts.preferencesDone(email))
        : AuthOutcome.failed(error);
  }

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) async {
    final error = _accounts.signIn(email: email, password: password);
    return error == null
        ? AuthOutcome.success(preferencesDone: _accounts.preferencesDone(email))
        : AuthOutcome.failed(error);
  }

  @override
  Future<void> completePreferences(PlayerPreferences prefs) async {
    final email = ref.read(sessionProvider)?.email;
    if (email != null) _accounts.markPreferencesDone(email);
  }

  @override
  Future<void> signOut() async => ref.read(sessionProvider.notifier).signOut();
}

/// Supabase Auth. Profil (nama, preferensi, tanda preferensi selesai) ada di
/// tabel `profiles`, dibuat otomatis oleh trigger saat akun dibuat.
class SupabaseAuthService implements AuthService {
  const SupabaseAuthService(this.client, this.ref);
  final SupabaseClient client;
  final Ref ref;

  @override
  Future<AuthOutcome> register({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await client.auth.signUp(
      email: normalizeEmail(email),
      password: password,
      data: {'name': name.trim()},
    );
    // Dengan "Confirm email" aktif, sesi baru ada setelah email diverifikasi.
    if (res.session == null) return const AuthOutcome.verifyEmail();
    return const AuthOutcome.success(preferencesDone: false);
  });

  @override
  Future<AuthOutcome> signIn({
    required String email,
    required String password,
  }) => _guard(() async {
    final res = await client.auth.signInWithPassword(
      email: normalizeEmail(email),
      password: password,
    );
    final row = await client
        .from('profiles')
        .select('prefs_done, area, level, weekdays')
        .eq('id', res.user!.id)
        .maybeSingle();
    final done = row?['prefs_done'] == true;
    if (done) {
      ref.read(preferencesProvider.notifier).save(profileToPreferences(row!));
    }
    return AuthOutcome.success(preferencesDone: done);
  });

  @override
  Future<void> completePreferences(PlayerPreferences prefs) async {
    final id = client.auth.currentUser?.id;
    if (id == null) return;
    await client
        .from('profiles')
        .update({...preferencesToProfile(prefs), 'prefs_done': true})
        .eq('id', id);
  }

  @override
  Future<void> signOut() => client.auth.signOut();

  static Future<AuthOutcome> _guard(Future<AuthOutcome> Function() run) async {
    try {
      return await run();
    } on AuthException catch (e) {
      return AuthOutcome.failed(authErrorFromSupabase(e));
    } on PostgrestException {
      return const AuthOutcome.failed(AuthError.unknown);
    } on Exception {
      return const AuthOutcome.failed(AuthError.network);
    }
  }
}

/// Menerjemahkan galat Supabase Auth ke pesan yang bisa ditindaklanjuti.
AuthError authErrorFromSupabase(AuthException e) => switch (e.code) {
  'user_already_exists' || 'email_exists' => AuthError.emailTaken,
  'invalid_credentials' => AuthError.invalidCredentials,
  'email_not_confirmed' => AuthError.emailNotConfirmed,
  'weak_password' => AuthError.weakPassword,
  'over_request_rate_limit' ||
  'over_email_send_rate_limit' => AuthError.tooManyAttempts,
  _ when e.statusCode == '429' => AuthError.tooManyAttempts,
  _ => AuthError.unknown,
};

/// Kolom preferensi di tabel `profiles`.
Map<String, Object?> preferencesToProfile(PlayerPreferences p) => {
  'area': p.area,
  'level': p.level?.name,
  'weekdays': p.weekdays.toList()..sort(),
};

PlayerPreferences profileToPreferences(Map<String, dynamic> row) {
  final level = row['level'] as String?;
  return PlayerPreferences(
    area: (row['area'] as String?) ?? const PlayerPreferences().area,
    level: level == null ? null : Level.values.byName(level),
    weekdays: {
      for (final d in (row['weekdays'] as List? ?? const [])) d as int,
    },
  );
}

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? LocalAuthService(ref)
      : SupabaseAuthService(client, ref);
});

/// Semua akun di HP ini, dengan email (huruf kecil) sebagai kunci. Akun
/// contoh selalu ada.
class AccountsNotifier extends Notifier<Map<String, LocalAccount>> {
  @override
  Map<String, LocalAccount> build() {
    final store = ref.watch(localStoreProvider);
    listenSelf(
      (_, next) => writeCached(store, CacheKeys.accounts, {
        for (final a in next.values) a.email: a.toJson(),
      }),
    );
    final saved = readCached<Map<String, LocalAccount>>(
      store,
      CacheKeys.accounts,
      (json) => {
        for (final e in (json! as Map).entries)
          e.key as String: LocalAccount.fromJson(
            (e.value as Map).cast<String, Object?>(),
          ),
      },
      const {},
    );
    return {demoEmail: demoAccount(), ...saved};
  }

  /// Membuat akun baru lalu langsung masuk. Akun baru belum terverifikasi.
  AuthError? register({
    required String name,
    required String email,
    required String password,
  }) {
    final key = normalizeEmail(email);
    if (state.containsKey(key)) return AuthError.emailTaken;
    final salt = newSalt();
    final account = LocalAccount(
      name: name.trim(),
      email: key,
      salt: salt,
      passwordHash: hashPassword(password, salt),
    );
    state = {...state, key: account};
    _open(account);
    return null;
  }

  /// Masuk ke akun yang sudah ada.
  AuthError? signIn({required String email, required String password}) {
    final account = state[normalizeEmail(email)];
    if (account == null) return AuthError.notRegistered;
    if (!account.checkPassword(password)) return AuthError.wrongPassword;
    _open(account);
    return null;
  }

  /// Dipanggil setelah halaman preferensi diisi atau dilewati, supaya
  /// halaman itu tidak muncul lagi di akun ini.
  void markPreferencesDone(String email) {
    final key = normalizeEmail(email);
    final account = state[key];
    if (account == null || account.preferencesDone) return;
    state = {...state, key: account.copyWith(preferencesDone: true)};
  }

  bool preferencesDone(String email) =>
      state[normalizeEmail(email)]?.preferencesDone ?? true;

  void _open(LocalAccount a) => ref
      .read(sessionProvider.notifier)
      .signInEmail(name: a.name, email: a.email, newAccount: !a.emailVerified);
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, Map<String, LocalAccount>>(
      AccountsNotifier.new,
    );
