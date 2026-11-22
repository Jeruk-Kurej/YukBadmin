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

/// Pengguna yang sedang masuk. Null berarti belum masuk.
class SessionUser {
  const SessionUser({required this.name, required this.email});
  final String name;
  final String email;

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
        next == null ? null : {'name': next.name, 'email': next.email},
      ),
    );
    return readCached<SessionUser?>(store, CacheKeys.session, (json) {
      final m = json! as Map<String, Object?>;
      return SessionUser(
        name: m['name']! as String,
        email: m['email']! as String,
      );
    }, null);
  }

  /// Sementara masuk sebagai akun contoh; nanti diganti Google sign-in Supabase.
  void signInDemo() =>
      state = const SessionUser(name: 'Bryan Carlie', email: 'bryan@contoh.id');

  void signOut() => state = null;
}

final sessionProvider = NotifierProvider<SessionNotifier, SessionUser?>(
  SessionNotifier.new,
);

class PreferencesNotifier extends Notifier<PlayerPreferences> {
  @override
  PlayerPreferences build() {
    final store = ref.watch(localStoreProvider);
    listenSelf(
      (_, next) =>
          writeCached(store, CacheKeys.preferences, preferencesToJson(next)),
    );
    return readCached(
      store,
      CacheKeys.preferences,
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
    listenSelf((_, next) => writeCached(store, CacheKeys.saved, next.toList()));
    return readCached<Set<String>>(
      store,
      CacheKeys.saved,
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
