import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/features/account/data/activity_feed.dart';
import 'package:yukbadmin/features/club/data/club_models.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

/// Senin, 16 November 2026 pukul 10.00.
final _now = DateTime(2026, 11, 16, 10);

SessionEvent _event(String id, DateTime start, {Due? due, bool rsvp = false}) =>
    SessionEvent(
      id: id,
      title: 'Latihan rutin',
      start: start,
      durationMinutes: 120,
      venue: 'GOR Uji',
      dues: {'m1': ?due},
      rsvps: {if (rsvp) 'm1': Rsvp.ikut},
    );

Membership _membership(List<SessionEvent> events) => Membership(
  pbId: 'pb-uji',
  memberId: 'm1',
  type: MemberType.tetap,
  events: events,
  fee: 50000,
);

void main() {
  group('riwayat transaksi', () {
    test('status iuran mengikuti lunas, bukti, dan batal', () {
      final entries = dueEntries([
        _membership([
          _event(
            'lunas',
            _now.subtract(const Duration(days: 7)),
            due: Due(amount: 50000, paid: true, paidAt: _now),
          ),
          _event(
            'cek',
            _now.subtract(const Duration(days: 3)),
            due: Due(
              amount: 50000,
              proof: PaymentProof(path: '/a.jpg', sentAt: _now),
            ),
          ),
          _event(
            'tolak',
            _now.subtract(const Duration(days: 2)),
            due: Due(
              amount: 50000,
              proof: PaymentProof(
                path: '/b.jpg',
                sentAt: _now,
                status: ProofStatus.ditolak,
                reason: 'Nominal tidak terbaca',
              ),
            ),
          ),
          _event(
            'belum',
            _now.subtract(const Duration(days: 1)),
            due: const Due(amount: 50000),
          ),
        ]),
      ]);
      // Urut dari sesi terbaru.
      expect(
        [for (final e in entries) e.state],
        [DueState.unpaid, DueState.rejected, DueState.checking, DueState.paid],
      );
    });

    test('notifikasi: yang perlu tindakan di atas, lalu info', () {
      final notices = playerNotices(
        [
          _membership([
            // Sesi besok yang belum dijawab.
            _event('besok', _now.add(const Duration(days: 1))),
            // Sesi minggu depan tidak diingatkan dulu.
            _event('nanti', _now.add(const Duration(days: 6))),
            _event(
              'lunas',
              _now.subtract(const Duration(days: 3)),
              due: Due(
                amount: 50000,
                paid: true,
                paidAt: _now.subtract(const Duration(days: 1)),
              ),
            ),
            _event(
              'belum',
              _now.subtract(const Duration(days: 2)),
              due: const Due(amount: 50000),
            ),
          ]),
        ],
        _now,
        {'pb-uji': 'PB Uji'},
      );
      expect(notices.length, 3);
      expect(notices.take(2).every((n) => n.needsAction), isTrue);
      expect(notices.last.kind, NoticeKind.paid);
      expect(notices.any((n) => n.message.contains('PB Uji')), isTrue);
    });
  });

  group('di layar', () {
    Future<ProviderContainer> start(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [nowProvider.overrideWithValue(() => _now)],
          child: const YukBadminApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      c.read(sessionProvider.notifier).signInDemo();
      await tester.pumpAndSettle();
      return c;
    }

    testWidgets('Akun membuka riwayat transaksi dan notifikasi', (
      tester,
    ) async {
      final c = await start(tester);
      c.read(routerProvider).go('/akun');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Riwayat transaksi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Riwayat transaksi'));
      await tester.pumpAndSettle();
      expect(find.text('Sudah dibayar'), findsOneWidget);
      expect(find.textContaining('toko partner'), findsOneWidget);

      await tester.tap(find.text('Lunas').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Notifikasi'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifikasi'));
      await tester.pumpAndSettle();
      expect(find.text('Perlu tindakan'), findsWidgets);
      expect(find.textContaining('Notifikasi ke HP menyusul'), findsOneWidget);
    });

    testWidgets('layar kecil dan teks besar tidak meluber', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await start(tester, size: const Size(320, 640));
      final router = c.read(routerProvider);
      for (final path in ['/beranda', '/cari', '/perlengkapan', '/akun']) {
        router.go(path);
        await tester.pumpAndSettle();
      }
      router.push('/riwayat');
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      router.push('/notifikasi');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
