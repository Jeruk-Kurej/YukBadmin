import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/core/widgets/yb_widgets.dart';
import 'package:yukbadmin/features/manage/data/manage_codec.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/pb_repository.dart';

void main() {
  final now = DateTime(2026, 11, 1, 10);
  late MemoryLocalStore store;
  late ProviderContainer c;
  late ManageNotifier n;
  late String e, a, b;
  late int fee;

  ProviderContainer open() {
    final container = ProviderContainer(
      overrides: [
        nowProvider.overrideWithValue(() => now),
        localStoreProvider.overrideWithValue(store),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> setUpPb(DuesTiming timing) async {
    store = MemoryLocalStore();
    c = open();
    final pb = (await const SeedPbRepository().fetchAll()).first;
    fee = pb.feePerSession;
    n = c.read(manageProvider.notifier);
    n.registerPb(pb);
    n.setDuesSystem(DuesSystem(timing: timing));
    a = n.addMember(name: 'Andi', type: MemberType.tetap).id;
    b = n.addMember(name: 'Budi', type: MemberType.tetap).id;
    e = n
        .addEvent(
          title: 'Uji',
          start: now.add(const Duration(days: 5)),
          durationMinutes: 120,
          venue: 'GOR',
        )
        .id;
  }

  SessionEvent event() => c.read(manageProvider).eventById(e)!;
  Due? due(String member) => event().dues[member];

  void paidThenRefunded() {
    n.setRsvp(e, a, Rsvp.ikut);
    n.setPaid(e, a, true);
    n.setRsvp(e, a, Rsvp.tidak);
    n.markRefunded(e, a);
  }

  group('batal dan ikut lagi', () {
    setUp(() => setUpPb(DuesTiming.sebelum));

    test('ikut lagi setelah uang kembali ditagih ulang', () {
      paidThenRefunded();
      n.setRsvp(e, a, Rsvp.ikut);
      expect(due(a)!.paid, isFalse);
      expect(due(a)!.paidAt, isNull);
      expect(due(a)!.refund, isNull);
      expect(due(a)!.amount, fee);
    });

    test('ikut lagi sebelum uang dikembalikan tetap lunas', () {
      n.setRsvp(e, a, Rsvp.ikut);
      n.setPaid(e, a, true);
      n.setRsvp(e, a, Rsvp.tidak);
      n.setRsvp(e, a, Rsvp.ikut);
      expect(due(a)!.paid, isTrue);
      expect(due(a)!.refund, isNull);
    });

    test('hadir setelah uang kembali ditagih ulang', () {
      paidThenRefunded();
      n.saveAttendance(e, {a});
      expect(due(a)!.paid, isFalse);
      expect(due(a)!.refund, isNull);
    });

    test('batal dua kali tidak membuka pengembalian baru', () {
      paidThenRefunded();
      n.setRsvp(e, a, Rsvp.tidak);
      expect(due(a)!.refund!.status, RefundStatus.selesai);
    });

    test('pengembalian yang sudah selesai tidak bisa diajukan lagi', () {
      paidThenRefunded();
      n.requestRefund(e, a, 'sakit');
      expect(due(a)!.refund!.status, RefundStatus.selesai);
    });
  });

  group('batal saat bukti menunggu dicek', () {
    setUp(() async {
      await setUpPb(DuesTiming.sebelum);
      n.setRsvp(e, a, Rsvp.ikut);
      n.submitProof(e, a, '/bukti.jpg');
      n.setRsvp(e, a, Rsvp.tidak);
    });

    test('bukti tetap bisa dicek, tapi tidak ditagih', () {
      expect(due(a)!.awaitingCheck, isTrue);
      expect(event().outstanding, 0);
      expect(event().unpaidCount, 0);
    });

    test('disetujui berarti uangnya perlu dikembalikan', () {
      n.approveProof(e, a);
      expect(due(a)!.paid, isTrue);
      expect(due(a)!.refund!.status, RefundStatus.perlu);
      expect(due(a)!.refund!.cancelledAt, now);
    });

    test('ditandai lunas manual juga membuka pengembalian', () {
      n.setPaid(e, a, true);
      expect(due(a)!.refund!.status, RefundStatus.perlu);
      n.setPaid(e, a, false);
      expect(due(a)!.refund, isNull);
    });

    test('ditolak: bukti tetap ada dan tidak ikut diingatkan', () {
      n.rejectProof(e, a, 'Foto buram');
      expect(due(a)!.proof!.status, ProofStatus.ditolak);
      expect(due(a)!.billable, isFalse);
      expect(event().remindableCount, 0);
    });

    test('ikut lagi membuat tagihan aktif kembali', () {
      n.setRsvp(e, a, Rsvp.ikut);
      expect(due(a)!.cancelledAt, isNull);
      expect(event().outstanding, fee);
    });

    test('waktu batal tersimpan di cache', () {
      final restored = eventFromJson(eventToJson(event()));
      expect(restored.dues[a]!.cancelledAt, now);
    });
  });

  test('batal mepet lalu bukti disetujui: tidak otomatis kembali', () async {
    await setUpPb(DuesTiming.sebelum);
    n.setDuesSystem(const DuesSystem(cancelHours: 168));
    n.setRsvp(e, a, Rsvp.ikut);
    n.submitProof(e, a, '/bukti.jpg');
    n.setRsvp(e, a, Rsvp.tidak);
    n.approveProof(e, a);
    expect(due(a)!.refund!.status, RefundStatus.tidakKembali);
  });

  group('iuran per orang', () {
    setUp(() => setUpPb(DuesTiming.perOrang));

    test('simpan ulang kehadiran tidak menghapus tagihan', () {
      n.saveAttendance(e, {a, b});
      n.setUsage(e, a, const Usage(matches: 3, shuttles: 1));
      n.sendBills(e);
      n.saveAttendance(e, {a, b});
      expect(due(a)!.amount, 34000);
    });

    test('pemain yang match-nya dihapus tidak lagi ditagih', () {
      n.setMatches(e, [
        MatchRecord(court: 1, players: [a]),
        MatchRecord(court: 1, players: [b]),
      ]);
      n.sendBills(e);
      n.setMatches(e, [
        MatchRecord(court: 1, players: [a]),
      ]);
      n.sendBills(e);
      expect(due(a), isNotNull);
      expect(due(b), isNull);
    });

    test('pemakaian dinolkan tidak menghapus bukti transfer', () {
      n.setUsage(e, a, const Usage(matches: 1));
      n.sendBills(e);
      n.submitProof(e, a, '/bukti.jpg');
      n.setUsage(e, a, const Usage());
      n.sendBills(e);
      expect(due(a)!.proof, isNotNull);
    });

    test('hapus member menjaga uang terkumpul tanpa tagihan hantu', () {
      n.setUsage(e, a, const Usage(matches: 2));
      n.sendBills(e);
      n.setPaid(e, a, true);
      final collected = event().collected;
      n.removeMember(a);
      expect(event().collected, collected);
      expect(event().usage.containsKey(a), isFalse);
      n.sendBills(e);
      expect(due(a)!.paid, isTrue);
    });

    test('hapus member yang belum bayar: match lama tidak menagihnya', () {
      n.setMatches(e, [
        MatchRecord(court: 1, players: [a, b]),
      ]);
      n.sendBills(e);
      n.removeMember(a);
      expect(due(a), isNull);
      n.setMatches(e, [...event().matches]);
      n.sendBills(e);
      expect(due(a), isNull);
    });

    test('id member terhapus tidak dipakai ulang setelah app dibuka', () {
      n.setUsage(e, b, const Usage(matches: 1));
      n.sendBills(e);
      n.setPaid(e, b, true);
      n.removeMember(b);
      final reopened = open();
      final added = reopened
          .read(manageProvider.notifier)
          .addMember(name: 'Citra', type: MemberType.tetap);
      expect(added.id, isNot(b));
    });
  });

  testWidgets('kotak pilihan di dalam Wrap tidak selebar layar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              for (final label in ['Sen', 'Sel'])
                YbChoiceChip(
                  round: true,
                  label: label,
                  selected: false,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byType(YbChoiceChip).first);
    final second = tester.getRect(find.byType(YbChoiceChip).last);
    expect(first.width, lessThan(100));
    expect(second.top, first.top);
  });
}
