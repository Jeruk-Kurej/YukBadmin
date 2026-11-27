import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../../pb/state/providers.dart';
import '../data/local_accounts.dart';

/// Alasan daftar atau masuk ditolak.
enum AuthError {
  emailTaken('Email ini sudah terdaftar. Pilih Masuk, atau pakai email lain.'),
  notRegistered('Email ini belum terdaftar. Pilih Daftar untuk membuat akun.'),
  wrongPassword('Kata sandi salah. Cek lagi huruf besar dan kecilnya.');

  const AuthError(this.message);
  final String message;
}

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
