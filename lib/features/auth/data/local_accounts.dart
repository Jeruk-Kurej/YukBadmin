import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Akun yang tersimpan di HP ini. Sementara menggantikan Supabase Auth:
/// daftar dan masuk sudah dicek (akun harus ada, kata sandi harus cocok),
/// tapi belum ada server, jadi akun tidak pindah ke HP lain dan email belum
/// bisa diverifikasi.
class LocalAccount {
  const LocalAccount({
    required this.name,
    required this.email,
    required this.salt,
    required this.passwordHash,
    this.emailVerified = false,
    this.preferencesDone = false,
  });

  final String name;

  /// Selalu huruf kecil.
  final String email;
  final String salt;
  final String passwordHash;
  final bool emailVerified;

  /// Halaman "Atur preferensi mainmu" sudah dilewati atau diisi.
  final bool preferencesDone;

  bool checkPassword(String password) =>
      hashPassword(password, salt) == passwordHash;

  LocalAccount copyWith({bool? preferencesDone}) => LocalAccount(
    name: name,
    email: email,
    salt: salt,
    passwordHash: passwordHash,
    emailVerified: emailVerified,
    preferencesDone: preferencesDone ?? this.preferencesDone,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'email': email,
    'salt': salt,
    'hash': passwordHash,
    'verified': emailVerified,
    'prefsDone': preferencesDone,
  };

  static LocalAccount fromJson(Map<String, Object?> m) => LocalAccount(
    name: m['name']! as String,
    email: m['email']! as String,
    salt: m['salt']! as String,
    passwordHash: m['hash']! as String,
    emailVerified: (m['verified'] as bool?) ?? false,
    preferencesDone: (m['prefsDone'] as bool?) ?? false,
  );
}

/// Kata sandi tidak disimpan apa adanya: yang disimpan hanya hash SHA-256
/// dari salt acak dan kata sandi.
String hashPassword(String password, String salt) =>
    sha256.convert(utf8.encode('$salt:$password')).toString();

String newSalt([Random? random]) {
  final r = random ?? Random.secure();
  return base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
}

String normalizeEmail(String email) => email.trim().toLowerCase();

/// Akun contoh untuk demo dan tes. Datanya (member, PB-ku) hanya muncul di
/// akun ini. Kata sandi contoh ini sengaja ditulis di kode karena bukan akun
/// sungguhan; hapus saat Supabase Auth dipasang.
const demoName = 'Bryan Carlie';
const demoEmail = 'bryan@contoh.id';
const demoPassword = 'yukbadmin123';
const _demoSalt = 'akun-contoh-yukbadmin';

LocalAccount demoAccount() => LocalAccount(
  name: demoName,
  email: demoEmail,
  salt: _demoSalt,
  passwordHash: hashPassword(demoPassword, _demoSalt),
  emailVerified: true,
);
