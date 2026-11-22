import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/app/tours.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

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
  about: '',
  rules: [],
  manager: PbManager(name: 'Bryan Carlie', whatsapp: '6281234567890'),
  openForNewMembers: true,
  artSeed: 0,
);

void main() {
  Future<ProviderContainer> start(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool withPb = false,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapTilesEnabledProvider.overrideWithValue(false),
          nowProvider.overrideWithValue(() => DateTime(2026, 11, 16, 10)),
        ],
        child: const YukBadminApp(),
      ),
    );
    final c = ProviderScope.containerOf(
      tester.element(find.byType(YukBadminApp)),
    );
    c.read(sessionProvider.notifier).signInDemo();
    if (withPb) {
      c.read(manageProvider.notifier)
        ..registerPb(_pb)
        ..addMember(name: 'Andi Pratama', type: MemberType.tetap);
    }
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  /// Tombol di balon tur (Lanjut, Lewati, Selesai, atau tombol tambahan).
  Future<void> tapBubble(WidgetTester tester, String text) async {
    await tester.tap(
      find.descendant(of: find.byType(OverflowBar), matching: find.text(text)),
    );
    await tester.pumpAndSettle();
  }

  String location(ProviderContainer c) =>
      c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

  group('tur pemain', () {
    testWidgets('berjalan per tab dan berhenti di pintu daftar PB', (
      tester,
    ) async {
      final c = await start(tester);
      expect(find.text('Baru di YukBadmin?'), findsOneWidget);

      await tapText(tester, 'Mulai tur');
      expect(find.text('Langkah 1 dari 5'), findsOneWidget);
      expect(location(c), '/beranda');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Saring yang cocok'), findsOneWidget);
      expect(location(c), '/cari');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Bingung pilih raket?'), findsOneWidget);
      expect(location(c), '/perlengkapan');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Langkah 4 dari 5'), findsOneWidget);
      expect(location(c), '/akun');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Punya PB?'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);

      // Tombol tambahan di langkah terakhir membuka pendaftaran PB.
      await tapBubble(tester, 'Daftarkan PB');
      expect(find.text('Langkah 1 dari 3'), findsOneWidget);
      expect(find.text('Punya PB?'), findsNothing);
      expect(c.read(playerTourSeenProvider), isTrue);
    });

    testWidgets('dilewati, ajakan hilang, bisa diulang dari Akun', (
      tester,
    ) async {
      final c = await start(tester);
      await tapText(tester, 'Mulai tur');
      await tapBubble(tester, 'Lewati');
      expect(find.text('Langkah 1 dari 5'), findsNothing);
      expect(find.text('Baru di YukBadmin?'), findsNothing);
      expect(c.read(playerTourSeenProvider), isTrue);

      c.read(routerProvider).go('/akun');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tur aplikasi'));
      await tester.pumpAndSettle();
      await tapText(tester, 'Tur aplikasi');
      expect(find.text('Langkah 1 dari 5'), findsOneWidget);
    });

    testWidgets('ajakan bisa ditutup tanpa ikut tur', (tester) async {
      final c = await start(tester);
      await tester.tap(find.byTooltip('Tutup ajakan tur'));
      await tester.pumpAndSettle();
      expect(find.text('Baru di YukBadmin?'), findsNothing);
      expect(c.read(playerTourSeenProvider), isTrue);
    });

    testWidgets('pemain yang sudah punya PB diarahkan ke Beralih', (
      tester,
    ) async {
      await start(tester, withPb: true);
      await tapText(tester, 'Mulai tur');
      for (var i = 0; i < 4; i++) {
        await tapBubble(tester, 'Lanjut');
      }
      expect(find.text('Kamu juga pengurus'), findsOneWidget);
      await tapBubble(tester, 'Selesai');
      expect(find.text('Kamu juga pengurus'), findsNothing);
    });
  });

  group('tur pengurus', () {
    testWidgets('dimulai dari kotak di dashboard sampai selesai', (
      tester,
    ) async {
      final c = await start(tester, withPb: true);
      c.read(routerProvider).go('/kelola/beranda');
      await tester.pumpAndSettle();
      expect(find.text('Baru jadi pengurus?'), findsOneWidget);

      await tapText(tester, 'Mulai tur');
      expect(find.text('Kumpulkan member'), findsOneWidget);
      expect(location(c), '/kelola/member');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Langkah 2 dari 5'), findsOneWidget);
      expect(location(c), '/kelola/jadwal');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Tandai iuran'), findsOneWidget);
      expect(location(c), '/kelola/iuran');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Ajak pengurus lain'), findsOneWidget);
      expect(location(c), '/kelola/profil');

      await tapBubble(tester, 'Lanjut');
      expect(find.text('Halaman PB-mu'), findsOneWidget);
      await tapBubble(tester, 'Selesai');
      expect(find.text('Halaman PB-mu'), findsNothing);
      expect(c.read(managerGuideSeenProvider), isTrue);

      // Tombol tanda tanya di dashboard mengulang tur.
      c.read(routerProvider).go('/kelola/beranda');
      await tester.pumpAndSettle();
      expect(find.text('Baru jadi pengurus?'), findsNothing);
      await tester.tap(find.byTooltip('Mulai tur pengurus'));
      await tester.pumpAndSettle();
      expect(find.text('Kumpulkan member'), findsOneWidget);
    });

    testWidgets('tanpa sesi, langkah jadwal menyorot Buat sesi', (
      tester,
    ) async {
      final c = await start(tester, withPb: true);
      for (final e in c.read(manageProvider).events) {
        c.read(manageProvider.notifier).removeEvent(e.id);
      }
      c.read(routerProvider).go('/kelola/beranda');
      await tester.pumpAndSettle();
      await tapText(tester, 'Mulai tur');
      await tapBubble(tester, 'Lanjut');
      expect(find.text('Langkah 2 dari 5'), findsOneWidget);
      expect(find.text('Catat kehadiran'), findsOneWidget);
    });
  });

  testWidgets('kedua tur di layar kecil dan teks besar tidak meluber', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await start(tester, size: const Size(320, 640), withPb: true);
    await tapText(tester, 'Mulai tur');
    for (var i = 0; i < 4; i++) {
      await tapBubble(tester, 'Lanjut');
    }
    await tapBubble(tester, 'Selesai');

    c.read(routerProvider).go('/kelola/beranda');
    await tester.pumpAndSettle();
    await tapText(tester, 'Mulai tur');
    for (var i = 0; i < 4; i++) {
      await tapBubble(tester, 'Lanjut');
    }
    expect(find.text('Halaman PB-mu'), findsOneWidget);
    await tapBubble(tester, 'Selesai');
  });
}
