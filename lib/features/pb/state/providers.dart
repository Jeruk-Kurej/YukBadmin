import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/local_store.dart';
import '../data/pb_codec.dart';
import '../data/pb_models.dart';
import '../../manage/state/manage_providers.dart';
import '../data/pb_repository.dart';

final pbRepositoryProvider = Provider<PbRepository>(
  (ref) => const SeedPbRepository(),
);

/// Gambar peta diunduh dari OpenStreetMap. Tes mematikannya karena tes
/// tidak boleh mengakses jaringan.
final mapTilesEnabledProvider = Provider<bool>((ref) => true);

/// Semua PB yang terdaftar, termasuk PB yang didaftarkan pengguna sendiri.
final pbListProvider = FutureProvider<List<Pb>>((ref) async {
  final own = ref.watch(manageProvider.select((s) => s.pb));
  final list = await ref.watch(pbRepositoryProvider).fetchAll();
  return [?own, ...list];
});

final pbByIdProvider = Provider.family<AsyncValue<Pb?>, String>((ref, id) {
  return ref
      .watch(pbListProvider)
      .whenData((list) => list.where((pb) => pb.id == id).firstOrNull);
});

/// Kunci cache untuk data milik akun yang sedang masuk, supaya tiap akun punya
/// datanya sendiri dan tidak hilang saat keluar. Data dari versi lama (satu
/// kunci untuk semua akun) dipindahkan ke akun pertama yang membukanya.
String accountCacheKey(Ref ref, String base) {
  final store = ref.watch(localStoreProvider);
  final email = ref.watch(sessionProvider.select((s) => s?.email));
  if (email == null) return base;
  final key = '$base:${email.toLowerCase()}';
  final old = store.read(base);
  if (old != null && store.read(key) == null) {
    store.write(key, old);
    store.remove(base);
  }
  return key;
}

/// Pengguna yang sedang masuk. Null berarti belum masuk.
class SessionUser {
  const SessionUser({
    required this.name,
    required this.email,
    this.emailVerified = true,
  });
  final String name;
  final String email;

  /// Daftar dengan email belum diverifikasi. Tidak menahan pengguna;
  /// hanya pengingat di Akun (P14b).
  final bool emailVerified;

  String get firstName => name.split(' ').first;

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}

class SessionNotifier extends Notifier<SessionUser?> {
  @override
  SessionUser? build() {
    final store = ref.watch(localStoreProvider);
    listenSelf(
      (_, next) => writeCached(
        store,
        CacheKeys.session,
        next == null
            ? null
            : {
                'name': next.name,
                'email': next.email,
                'emailVerified': next.emailVerified,
              },
      ),
    );
    return readCached<SessionUser?>(store, CacheKeys.session, (json) {
      final m = json! as Map<String, Object?>;
      return SessionUser(
        name: m['name']! as String,
        email: m['email']! as String,
        emailVerified: (m['emailVerified'] as bool?) ?? true,
      );
    }, null);
  }

  /// Langsung masuk ke akun contoh, tanpa kata sandi. Hanya untuk tes;
  /// layar Masuk memakai [AccountsNotifier].
  void signInDemo() =>
      state = const SessionUser(name: 'Bryan Carlie', email: 'bryan@contoh.id');

  /// Membuka sesi untuk akun yang sudah dicek [AccountsNotifier].
  void signInEmail({
    required String name,
    required String email,
    bool newAccount = false,
  }) =>
      state = SessionUser(name: name, email: email, emailVerified: !newAccount);

  void signOut() => state = null;
}

/// Pengaturan privasi: profil (nama, level, area) terlihat sesama member.
class ProfilePublicNotifier extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, CacheKeys.profilePublic);
    listenSelf((_, next) => writeCached(store, key, next));
    return readCached<bool>(
      store,
      key,
      (json) => json! as bool,
      // Mati sejak awal: tampil di daftar member harus dipilih sendiri.
      false,
    );
  }

  void set(bool value) => state = value;
}

final profilePublicProvider = NotifierProvider<ProfilePublicNotifier, bool>(
  ProfilePublicNotifier.new,
);

final sessionProvider = NotifierProvider<SessionNotifier, SessionUser?>(
  SessionNotifier.new,
);

class PreferencesNotifier extends Notifier<PlayerPreferences> {
  @override
  PlayerPreferences build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, CacheKeys.preferences);
    listenSelf((_, next) => writeCached(store, key, preferencesToJson(next)));
    return readCached(
      store,
      key,
      preferencesFromJson,
      const PlayerPreferences(),
    );
  }

  void save(PlayerPreferences prefs) => state = prefs;
}

final preferencesProvider =
    NotifierProvider<PreferencesNotifier, PlayerPreferences>(
      PreferencesNotifier.new,
    );

class FilterNotifier extends Notifier<PbFilter> {
  @override
  PbFilter build() => const PbFilter();

  void set(PbFilter filter) => state = filter;
  void setQuery(String query) => state = state.copyWith(query: query);
  void reset() => state = PbFilter(query: state.query);
}

final filterProvider = NotifierProvider<FilterNotifier, PbFilter>(
  FilterNotifier.new,
);

/// PB yang lolos filter aktif.
final filteredPbProvider = Provider<AsyncValue<List<Pb>>>((ref) {
  final filter = ref.watch(filterProvider);
  return ref
      .watch(pbListProvider)
      .whenData((list) => list.where(filter.matches).toList());
});

class SavedNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, CacheKeys.saved);
    listenSelf((_, next) => writeCached(store, key, next.toList()));
    return readCached<Set<String>>(
      store,
      key,
      (json) => {for (final id in json! as List) id as String},
      const {},
    );
  }

  /// Mengembalikan true kalau PB sekarang tersimpan.
  bool toggle(String pbId) {
    final next = {...state};
    final nowSaved = next.add(pbId);
    if (!nowSaved) next.remove(pbId);
    state = next;
    return nowSaved;
  }
}

final savedProvider = NotifierProvider<SavedNotifier, Set<String>>(
  SavedNotifier.new,
);

final savedPbProvider = Provider<AsyncValue<List<Pb>>>((ref) {
  final saved = ref.watch(savedProvider);
  return ref
      .watch(pbListProvider)
      .whenData((list) => list.where((pb) => saved.contains(pb.id)).toList());
});

/// PB yang sudah dihubungi pemain lewat WhatsApp, dengan waktunya.
/// Balasan pengurus tidak tercatat karena percakapan terjadi di WhatsApp.
class ContactedNotifier extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, CacheKeys.contacted);
    listenSelf(
      (_, next) => writeCached(store, key, {
        for (final e in next.entries) e.key: e.value.toIso8601String(),
      }),
    );
    return readCached<Map<String, DateTime>>(
      store,
      key,
      (json) => {
        for (final e in (json! as Map).entries)
          e.key as String: DateTime.parse(e.value as String),
      },
      const {},
    );
  }

  void mark(String pbId, DateTime at) => state = {...state, pbId: at};
}

final contactedProvider =
    NotifierProvider<ContactedNotifier, Map<String, DateTime>>(
      ContactedNotifier.new,
    );

/// PB yang sudah dihubungi, terbaru di atas.
final contactedPbProvider = Provider<List<(Pb, DateTime)>>((ref) {
  final contacted = ref.watch(contactedProvider);
  final list = ref.watch(pbListProvider).value ?? const <Pb>[];
  return [
    for (final pb in list)
      if (contacted[pb.id] case final at?) (pb, at),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
});

/// PB di area pemain, diurutkan dari sesi terdekat.
final nearbyPbProvider = Provider<AsyncValue<List<Pb>>>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return ref
      .watch(pbListProvider)
      .whenData((list) => list.where((pb) => pb.area == prefs.area).toList());
});

/// PB dengan skor kecocokan tertinggi terhadap preferensi pemain.
final recommendedPbProvider = Provider<AsyncValue<List<Pb>>>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return ref.watch(pbListProvider).whenData((list) {
    final scored = [...list]
      ..sort((a, b) => prefs.scoreFor(b).compareTo(prefs.scoreFor(a)));
    return scored.where((pb) => pb.openForNewMembers).take(3).toList();
  });
});
