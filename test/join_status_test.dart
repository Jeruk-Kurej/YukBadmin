import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/state/join_status.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

/// Senin, 16 November 2026 pukul 09.00: pemain menghubungi PB Smash.
final _contacted = DateTime(2026, 11, 16, 9);

void main() {
  group('status gabung', () {
    test('belum ditandai berarti menunggu sejak dihubungi', () {
      final r = joinRecordFor(const {}, 'pb-a', _contacted);
      expect(r.status, JoinStatus.menunggu);
      expect(r.updatedAt, _contacted);
    });

    test('ajakan hubungi lagi muncul setelah 2 hari menunggu', () {
      final r = joinRecordFor(const {}, 'pb-a', _contacted);
      expect(r.needsFollowUp(_contacted.add(const Duration(days: 1))), isFalse);
      expect(r.needsFollowUp(_contacted.add(const Duration(days: 2))), isTrue);
      final dibalas = JoinRecord(JoinStatus.dibalas, _contacted);
      expect(
        dibalas.needsFollowUp(_contacted.add(const Duration(days: 5))),
        isFalse,
      );
    });

    test('menghubungi lagi setelah status terakhir kembali menunggu', () {
      final records = {'pb-a': JoinRecord(JoinStatus.batal, _contacted)};
      expect(
        joinRecordFor(records, 'pb-a', _contacted).status,
        JoinStatus.batal,
      );
      final lagi = _contacted.add(const Duration(days: 3));
      expect(joinRecordFor(records, 'pb-a', lagi).status, JoinStatus.menunggu);
    });

    test('status tersimpan dan terbaca lagi dari cache', () {
      final store = MemoryLocalStore();
      final first = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      first
          .read(joinStatusProvider.notifier)
          .set('pb-a', JoinStatus.diterima, _contacted);
      first.dispose();

      final second = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      final r = second.read(joinStatusProvider)['pb-a'];
      expect(r?.status, JoinStatus.diterima);
      expect(r?.updatedAt, _contacted);
      second.dispose();
    });
  });

  group('di layar', () {
    Future<ProviderContainer> start(
      WidgetTester tester, {
      required DateTime now,
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nowProvider.overrideWithValue(() => now)],
          child: const YukBadminApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      c.read(sessionProvider.notifier).signInDemo();
      c.read(contactedProvider.notifier).mark('pb-smash-surabaya', _contacted);
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('pemain menandai pengurus sudah membalas', (tester) async {
      final c = await start(
        tester,
        now: _contacted.add(const Duration(hours: 5)),
      );
      c.read(routerProvider).push('/tersimpan');
      await tester.pumpAndSettle();
      expect(find.text('Menunggu balasan'), findsOneWidget);

      await tester.tap(find.text('PB Smash Surabaya'));
      await tester.pumpAndSettle();
      expect(find.text('Hubungi lagi lewat WhatsApp'), findsOneWidget);
      await tester.tap(find.text('Sudah dibalas'));
      await tester.pumpAndSettle();
      expect(find.text('Hubungi lagi lewat WhatsApp'), findsNothing);
      expect(
        c.read(joinStatusProvider)['pb-smash-surabaya']?.status,
        JoinStatus.dibalas,
      );

      await tester.tapAt(const Offset(200, 60));
      await tester.pumpAndSettle();
      expect(find.text('Sudah dibalas'), findsOneWidget);
    });

    testWidgets('belum dibalas 3 hari muncul di PB tersimpan dan Notifikasi', (
      tester,
    ) async {
      final c = await start(
        tester,
        now: _contacted.add(const Duration(days: 3)),
      );
      final router = c.read(routerProvider);
      router.push('/tersimpan');
      await tester.pumpAndSettle();
      expect(find.text('Belum dibalas'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      router.push('/notifikasi');
      await tester.pumpAndSettle();
      expect(find.text('PB Smash Surabaya belum membalas'), findsOneWidget);
      await tester.ensureVisible(find.text('Lihat PB tersimpan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lihat PB tersimpan'));
      await tester.pumpAndSettle();
      expect(find.text('Sudah kamu hubungi'), findsOneWidget);
    });

    testWidgets('layar kecil dan teks besar tidak meluber', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await start(
        tester,
        now: _contacted.add(const Duration(days: 3)),
        size: const Size(320, 640),
      );
      c.read(routerProvider).push('/tersimpan');
      await tester.pumpAndSettle();
      await tester.tap(find.text('PB Smash Surabaya'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Diterima'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Minta pengurus mencatatmu'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
