import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/data/local_store.dart';
import '../core/widgets/tour.dart';
import '../features/manage/state/manage_providers.dart';
import '../features/pb/state/providers.dart' show accountCacheKey;
import 'router.dart';

/// Bagian layar yang disorot tur. Tiap kunci dipasang di satu widget saja.
abstract final class TourKeys {
  // Pemain.
  static final homeSearch = GlobalKey(debugLabel: 'tur cari PB');
  static final searchFilter = GlobalKey(debugLabel: 'tur filter');
  static final gearAdvisor = GlobalKey(debugLabel: 'tur saran');
  static final accountClub = GlobalKey(debugLabel: 'tur PB-ku');
  static final accountManagerRole = GlobalKey(debugLabel: 'tur peran pengurus');

  // Pengurus.
  static final membersAdd = GlobalKey(debugLabel: 'tur tambah member');
  static final firstSessionAttendance = GlobalKey(
    debugLabel: 'tur catat kehadiran',
  );
  static final scheduleCreate = GlobalKey(debugLabel: 'tur buat sesi');
  static final duesTab = GlobalKey(debugLabel: 'tur tab iuran');
  static final profileManagers = GlobalKey(debugLabel: 'tur pengurus PB');
  static final profilePreview = GlobalKey(debugLabel: 'tur lihat halaman');
}

/// Apakah tur pemain sudah diikuti, dilewati, atau ajakannya ditutup.
class PlayerTourSeenNotifier extends Notifier<bool> {
  @override
  bool build() {
    final store = ref.watch(localStoreProvider);
    final key = accountCacheKey(ref, CacheKeys.playerTourSeen);
    listenSelf((_, next) => writeCached(store, key, next));
    return readCached(store, key, (j) => j! as bool, false);
  }

  void markSeen() => state = true;
}

final playerTourSeenProvider = NotifierProvider<PlayerTourSeenNotifier, bool>(
  PlayerTourSeenNotifier.new,
);

/// Tur pemain: cari PB, filter, saran perlengkapan, PB-ku, lalu berhenti di
/// pintu menjadi pengurus PB.
void startPlayerTour(BuildContext context, WidgetRef ref) {
  final router = ref.read(routerProvider);
  final seen = ref.read(playerTourSeenProvider.notifier);
  final hasPb = ref.read(manageProvider).hasPb;
  startTour(
    context,
    go: router.go,
    onClose: seen.markSeen,
    steps: [
      TourStep(
        location: '/beranda',
        targets: [TourKeys.homeSearch],
        title: 'Cari PB',
        body: 'Mulai dari PB di areamu. Semua PB bisa dicari di tab Cari.',
      ),
      TourStep(
        location: '/cari',
        targets: [TourKeys.searchFilter],
        title: 'Saring yang cocok',
        body: 'Pilih level, hari, dan biaya. Ikon peta menampilkan PB di sekitarmu.',
      ),
      TourStep(
        location: '/perlengkapan',
        targets: [TourKeys.gearAdvisor],
        title: 'Bingung pilih raket?',
        body: 'Jawab beberapa pertanyaan, lalu lihat saran beserta alasannya.',
      ),
      TourStep(
        location: '/akun',
        targets: [TourKeys.accountClub],
        title: 'PB-ku',
        body: 'Setelah jadi member, jadwal dan iuranmu ada di sini.',
      ),
      TourStep(
        location: '/akun',
        targets: [TourKeys.accountManagerRole],
        title: hasPb ? 'Kamu juga pengurus' : 'Punya PB?',
        body: hasPb
            ? 'Beralih ke Kelola PB kapan saja dari sini.'
            : 'Daftarkan PB-mu untuk mengelola member, jadwal, dan iuran.',
        extraLabel: hasPb ? null : 'Daftarkan PB',
        onExtra: hasPb ? null : () => router.push('/daftar-pb'),
      ),
    ],
  );
}

/// Tur pengurus: member, jadwal dan kehadiran, iuran, pengurus lain, lalu
/// halaman PB yang dilihat calon member.
void startManagerTour(BuildContext context, WidgetRef ref) {
  final router = ref.read(routerProvider);
  // Disimpan sekarang: widget pemanggil bisa sudah dilepas saat tur selesai.
  final guideSeen = ref.read(managerGuideSeenProvider.notifier);
  startTour(
    context,
    go: router.go,
    onClose: guideSeen.markSeen,
    steps: [
      TourStep(
        location: '/kelola/member',
        targets: [TourKeys.membersAdd],
        title: 'Kumpulkan member',
        body: 'Tambah satu per satu, atau impor daftar lama dari chat.',
      ),
      TourStep(
        location: '/kelola/jadwal',
        targets: [TourKeys.firstSessionAttendance, TourKeys.scheduleCreate],
        title: 'Catat kehadiran',
        body: 'Di tiap sesi, centang yang datang. Yang hadir otomatis masuk daftar iuran.',
      ),
      TourStep(
        location: '/kelola/iuran',
        targets: [TourKeys.duesTab],
        title: 'Tandai iuran',
        body: 'Tandai yang sudah bayar, cek bukti transfer, dan kirim pengingat lewat WhatsApp.',
      ),
      TourStep(
        location: '/kelola/profil',
        targets: [TourKeys.profileManagers],
        title: 'Ajak pengurus lain',
        body: 'Supaya pencatatan tidak bergantung pada satu orang.',
      ),
      TourStep(
        location: '/kelola/profil',
        targets: [TourKeys.profilePreview],
        title: 'Halaman PB-mu',
        body: 'Ini yang dilihat calon member. Jaga jadwal, level, dan iurannya tetap benar.',
      ),
    ],
  );
}
