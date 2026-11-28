import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/core/widgets/photo.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

/// Picker palsu: tidak membuka kamera, langsung mengembalikan path contoh.
/// Berkasnya tidak ada, jadi layar menampilkan gambar cadangan.
class _FakePicker implements PhotoPicker {
  _FakePicker({this.fail = false});

  final bool fail;
  var _n = 0;

  @override
  Future<String?> pick(PhotoSource source) async {
    if (fail) throw Exception('akses ditolak');
    return '/foto-uji/${source.name}-${++_n}.jpg';
  }
}

const _pb = Pb(
  id: 'pb-milikku',
  name: 'PB Uji',
  venue: 'GOR Uji',
  district: 'Gubeng',
  area: 'Surabaya Timur',
  memberCount: 0,
  quota: 30,
  minLevel: Level.d,
  maxLevel: Level.b,
  memberTypes: {MemberType.tetap},
  feePerSession: 150000,
  sessions: [
    PbSession(
      weekday: 3,
      startHour: 19,
      startMinute: 0,
      endHour: 22,
      endMinute: 0,
      venue: 'GOR Uji',
    ),
  ],
  about: 'Santai',
  rules: [],
  manager: PbManager(name: 'Bryan Carlie', whatsapp: '6281234567890'),
  openForNewMembers: true,
  artSeed: 0,
);

void main() {
  Future<ProviderContainer> start(
    WidgetTester tester, {
    PhotoPicker? picker,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          photoPickerProvider.overrideWithValue(picker ?? _FakePicker()),
        ],
        child: const YukBadminApp(),
      ),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(YukBadminApp)),
    );
    c.read(sessionProvider.notifier).signInDemo();
    c.read(manageProvider.notifier).registerPb(_pb);
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  test('path foto lama dicari di folder app yang sekarang', () {
    expect(
      resolvePhotoPath('/app-lama/Documents/foto/1.jpg', '/app-baru/Documents'),
      '/app-baru/Documents/foto/1.jpg',
    );
    expect(resolvePhotoPath('/lain/1.jpg', '/app-baru'), '/lain/1.jpg');
    expect(resolvePhotoPath('/x/foto/1.jpg', null), '/x/foto/1.jpg');
  });

  testWidgets('foto member ditambah lalu dihapus dengan konfirmasi', (
    tester,
  ) async {
    final c = await start(tester);
    c.read(routerProvider).go('/kelola/member');
    await tester.pumpAndSettle();
    c.read(routerProvider).push('/member/baru');
    await tester.pumpAndSettle();
    expect(find.text('Tambah foto'), findsOneWidget);

    await tap(tester, find.byTooltip('Ubah foto member'));
    expect(find.text('Hapus foto'), findsNothing);
    await tap(tester, find.text('Pilih dari galeri'));
    expect(find.text('Ubah foto'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Andi Pratama');
    await tap(tester, find.text('Simpan'));
    final andi = c.read(manageProvider).members.single;
    expect(andi.photoPath, '/foto-uji/gallery-1.jpg');

    // Hapus foto butuh konfirmasi.
    c.read(routerProvider).push('/member/${andi.id}');
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Ubah foto member'));
    await tap(tester, find.text('Hapus foto'));
    expect(find.text('Hapus foto ini?'), findsOneWidget);
    await tap(tester, find.text('Hapus foto').last);
    expect(find.text('Tambah foto'), findsOneWidget);
    await tap(tester, find.text('Simpan'));
    expect(c.read(manageProvider).members.single.photoPath, isNull);
  });

  testWidgets('foto PB dari profil muncul di galeri halaman PB', (
    tester,
  ) async {
    final c = await start(tester);
    c.read(routerProvider).go('/kelola/profil');
    await tester.pumpAndSettle();

    await tap(tester, find.byTooltip('Tambah foto'));
    await tap(tester, find.text('Ambil foto'));
    await tap(tester, find.byTooltip('Tambah foto'));
    await tap(tester, find.text('Pilih dari galeri'));
    expect(find.text('Sampul'), findsOneWidget);

    await tap(tester, find.text('Simpan perubahan'));
    expect(c.read(manageProvider).pb!.photoPaths, [
      '/foto-uji/camera-1.jpg',
      '/foto-uji/gallery-2.jpg',
    ]);

    c.read(routerProvider).push('/pb/pb-milikku');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Galeri'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Galeri'), findsOneWidget);
  });

  testWidgets('akses foto ditolak memunculkan pesan cara memperbaiki', (
    tester,
  ) async {
    final c = await start(tester, picker: _FakePicker(fail: true));
    c.read(routerProvider).go('/kelola/member');
    await tester.pumpAndSettle();
    c.read(routerProvider).push('/member/baru');
    await tester.pumpAndSettle();
    await tap(tester, find.byTooltip('Ubah foto member'));
    await tap(tester, find.text('Ambil foto'));
    expect(
      find.textContaining('Izinkan akses kamera atau galeri'),
      findsOneWidget,
    );
    expect(find.text('Tambah foto'), findsOneWidget);
  });

  testWidgets('form toko dengan sampul di layar kecil dan teks besar', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await start(tester, size: const Size(320, 640));
    c.read(routerProvider).go('/daftar-toko');
    await tester.pumpAndSettle();
    await tap(tester, find.text('Tambah sampul'));
    await tap(tester, find.text('Pilih dari galeri'));
    expect(find.text('Ubah sampul'), findsOneWidget);
  });
}
