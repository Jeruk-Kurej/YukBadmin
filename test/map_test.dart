import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/pb_repository.dart';
import 'package:yukbadmin/features/pb/pages/map_page.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

/// PB tanpa titik lokasi, seperti PB yang baru didaftarkan lewat app.
const _noLocation = Pb(
  id: 'pb-tanpa-lokasi',
  name: 'PB Tanpa Lokasi',
  venue: 'GOR Uji',
  district: 'Gubeng',
  area: 'Surabaya Timur',
  memberCount: 0,
  quota: 30,
  minLevel: Level.d,
  maxLevel: Level.b,
  memberTypes: {MemberType.tetap},
  feePerSession: 120000,
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
  about: '',
  rules: [],
  manager: PbManager(name: 'Bryan Carlie', whatsapp: '6281234567890'),
  openForNewMembers: true,
  artSeed: 0,
);

void main() {
  test('hanya PB yang punya titik lokasi yang ditaruh di peta', () async {
    final seed = await const SeedPbRepository().fetchAll();
    expect(pbsWithLocation(seed).length, seed.length);
    expect(pbsWithLocation([...seed, _noLocation]).length, seed.length);
  });

  test('"Cari di area ini" hanya menyisakan PB di dalam batas peta', () async {
    final seed = await const SeedPbRepository().fetchAll();
    // Kotak kecil di sekitar GOR Kertajaya (PB Smash Surabaya).
    final bounds = LatLngBounds(
      const LatLng(-7.285, 112.755),
      const LatLng(-7.275, 112.765),
    );
    final inside = pbsInBounds(pbsWithLocation(seed), bounds);
    expect(inside.map((pb) => pb.name), ['PB Smash Surabaya']);
  });

  group('Peta PB di layar', () {
    Finder pin(String name) => find.bySemanticsLabel(name);

    Future<ProviderContainer> openMap(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [mapTilesEnabledProvider.overrideWithValue(false)],
          child: const YukBadminApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cari PB'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Peta'));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
    }

    testWidgets('ketuk pin menampilkan PB, lalu buka detailnya', (
      tester,
    ) async {
      await openMap(tester);
      expect(find.text('Peta PB'), findsOneWidget);
      expect(find.textContaining('Ketuk pin'), findsOneWidget);
      expect(pin('PB Rajawali'), findsOneWidget);

      await tester.tap(pin('PB Rajawali'));
      await tester.pumpAndSettle();
      // Nama muncul di label pin dan di kartu bawah.
      expect(find.text('PB Rajawali'), findsNWidgets(2));
      expect(find.textContaining('Ketuk pin'), findsNothing);

      await tester.tap(find.text('PB Rajawali').last);
      await tester.pumpAndSettle();
      expect(find.text('Tanya pengurus'), findsOneWidget);
    });

    testWidgets('kembali ke daftar lewat tombol Daftar', (tester) async {
      await openMap(tester);
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();
      expect(find.text('PB terdaftar'), findsOneWidget);
    });

    testWidgets('peta ikut filter dan punya keadaan kosong', (tester) async {
      final container = await openMap(tester);

      container
          .read(filterProvider.notifier)
          .set(const PbFilter(levels: {Level.s}));
      await tester.pumpAndSettle();
      expect(find.text('Filter (1)'), findsOneWidget);
      expect(pin('PB Garuda Muda'), findsOneWidget);
      expect(pin('PB Rajawali'), findsNothing);

      container
          .read(filterProvider.notifier)
          .set(const PbFilter(query: 'tidak ada pb ini'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada PB yang cocok'), findsOneWidget);
      await tester.tap(find.text('Hapus semua filter'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada PB yang cocok'), findsNothing);
      expect(pin('PB Rajawali'), findsOneWidget);
    });

    testWidgets('geser peta lalu cari di area ini', (tester) async {
      await openMap(tester);
      expect(find.text('Cari di area ini'), findsNothing);
      await tester.drag(find.byType(FlutterMap), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('Cari di area ini'), findsOneWidget);

      await tester.tap(find.text('Cari di area ini'));
      await tester.pumpAndSettle();
      expect(find.textContaining('PB di area ini'), findsOneWidget);

      await tester.tap(find.byTooltip('Tampilkan semua PB'));
      await tester.pumpAndSettle();
      expect(find.textContaining('PB di area ini'), findsNothing);
    });

    testWidgets('PB tanpa titik lokasi disebut di petunjuk', (tester) async {
      final container = await openMap(tester);
      container.read(manageProvider.notifier).registerPb(_noLocation);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('1 PB lain belum punya titik lokasi'),
        findsOneWidget,
      );
    });

    testWidgets('layar kecil dan teks besar tidak meluber', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await openMap(tester, size: const Size(320, 640));
      expect(find.text('Peta PB'), findsOneWidget);
      await tester.tap(pin('PB Rajawali'));
      await tester.pumpAndSettle();
      expect(find.text('PB Rajawali'), findsNWidgets(2));
    });
  });
}
