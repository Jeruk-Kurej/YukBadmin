import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache lokal di perangkat, supaya data tidak hilang saat app ditutup.
/// Sementara menggantikan backend; nanti data utama pindah ke Supabase dan
/// cache ini cukup untuk preferensi kecil.
abstract interface class LocalStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> remove(String key);
}

/// Penyimpanan di memori. Dipakai di tes dan sebagai bawaan provider.
class MemoryLocalStore implements LocalStore {
  MemoryLocalStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);
}

/// Penyimpanan di perangkat lewat shared_preferences.
class PrefsLocalStore implements LocalStore {
  PrefsLocalStore(this._prefs);

  final SharedPreferencesWithCache _prefs;

  static Future<PrefsLocalStore> open() async => PrefsLocalStore(
    await SharedPreferencesWithCache.create(
      cacheOptions: const SharedPreferencesWithCacheOptions(),
    ),
  );

  @override
  String? read(String key) => _prefs.getString(key);

  @override
  Future<void> write(String key, String value) => _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}

/// Diganti dengan [PrefsLocalStore] di `main.dart`.
final localStoreProvider = Provider<LocalStore>((ref) => MemoryLocalStore());

/// Kunci cache. Naikkan versi kalau bentuk data berubah tidak kompatibel.
abstract final class CacheKeys {
  static const session = 'v1.session';
  static const preferences = 'v1.preferences';
  static const saved = 'v1.saved';
  static const manage = 'v1.manage';
  static const guideSeen = 'v1.guideSeen';
  static const ownShop = 'v1.ownShop';
  static const themeMode = 'v1.themeMode';
  static const membership = 'v1.membership';
  static const playerTourSeen = 'v1.playerTourSeen';
  static const profilePublic = 'v1.profilePublic';
  static const contacted = 'v1.contacted';
  static const accounts = 'v1.accounts';
}

/// Membaca nilai JSON dari cache. Data rusak atau versi lama diabaikan
/// (kembali ke [fallback]) supaya app tetap bisa dibuka.
T readCached<T>(
  LocalStore store,
  String key,
  T Function(Object? json) decode,
  T fallback,
) {
  final raw = store.read(key);
  if (raw == null) return fallback;
  try {
    return decode(jsonDecode(raw));
  } catch (error) {
    debugPrint('Cache $key tidak terbaca, diabaikan: $error');
    return fallback;
  }
}

/// Menulis nilai ke cache sebagai JSON. Null berarti hapus.
void writeCached(LocalStore store, String key, Object? json) {
  if (json == null) {
    store.remove(key);
  } else {
    store.write(key, jsonEncode(json));
  }
}

/// Angka terbesar di akhir id seperti "m-12", supaya id baru tidak bentrok
/// dengan id yang dipulihkan dari cache.
int maxIdSeq(Iterable<String> ids) {
  var max = 0;
  for (final id in ids) {
    final n = int.tryParse(id.split('-').last) ?? 0;
    if (n > max) max = n;
  }
  return max;
}
