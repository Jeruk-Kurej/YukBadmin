import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/features/club/data/club_repository.dart';
import 'package:yukbadmin/features/manage/pages/manage_widgets.dart';
import 'package:yukbadmin/features/manage/data/import_parser.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/pb_repository.dart';

void main() {
  final now = DateTime(2026, 11, 1, 10);

  group('tagihan setelah main', () {
    late ProviderContainer c;
    late ManageNotifier n;
    late String e, a, b;

    Future<void> setUpPb(DuesSystem system) async {
      c = ProviderContainer(
        overrides: [nowProvider.overrideWithValue(() => now)],
      );
      addTearDown(c.dispose);
      n = c.read(manageProvider.notifier);
      n.registerPb((await const SeedPbRepository().fetchAll()).first);
      n.setDuesSystem(system);
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

    test('tagihan otomatis mati: baru ditagih saat pengurus menagih', () async {
      await setUpPb(
        const DuesSystem(timing: DuesTiming.setelahTetap, autoBill: false),
      );
      n.saveAttendance(e, {a, b});
      expect(event().dues, isEmpty);
      expect(event().unbilledAttendees, {a, b});
      n.billAttendees(e);
      expect(event().dues.keys, {a, b});
      expect(event().unbilledAttendees, isEmpty);
    });

    test('tagihan otomatis nyala: dibuat saat kehadiran disimpan', () async {
      await setUpPb(const DuesSystem(timing: DuesTiming.setelahTetap));
      n.saveAttendance(e, {a});
      expect(event().dues.keys, {a});
    });

    test('yang tidak lagi hadir tidak ditagih per orang', () async {
      await setUpPb(const DuesSystem(timing: DuesTiming.perOrang));
      n.setUsage(e, a, const Usage(matches: 1));
      n.setUsage(e, b, const Usage(matches: 1));
      n.saveAttendance(e, {a});
      n.sendBills(e);
      expect(event().dues.keys, {a});
    });

    test('batal mendadak yang tidak kembali tetap uang PB', () async {
      await setUpPb(const DuesSystem(cancelHours: 168));
      n.setRsvp(e, a, Rsvp.ikut);
      n.setPaid(e, a, true);
      n.setRsvp(e, a, Rsvp.tidak);
      expect(event().collected, event().dues[a]!.amount);
    });
  });

  test('hanya akun contoh yang punya data member contoh', () {
    const repo = SeedMembershipRepository();
    expect(repo.forUser(SeedMembershipRepository.demoEmail, now), isNotEmpty);
    expect(repo.forUser('sinta@contoh.id', now), isEmpty);
  });

  test('tautan peta hanya menerima alamat web', () {
    expect(webUri('maps.app.goo.gl/abc')?.scheme, 'https');
    expect(webUri('https://maps.google.com/?q=gor'), isNotNull);
    for (final bad in ['tel:0812', 'javascript://x.y', 'di dekat pasar', '%']) {
      expect(webUri(bad), isNull, reason: bad);
    }
  });

  group('impor catatan', () {
    Future<ImportRow> one(String line) async =>
        (await const RuleBasedNoteParser().parse(line)).single;

    test('nomor HP bukan nominal', () async {
      for (final number in ['081234567890', '+62 812-3456-7890']) {
        final row = await one('Budi $number lunas');
        expect(row.name, 'Budi');
        expect(row.amount, isNull);
        expect(row.paid, isTrue);
      }
    });

    test('jam bukan bagian nama', () async {
      expect((await one('Andi 19.00')).name, 'Andi');
      expect((await one('Andi jam 19:00')).name, 'Andi');
    });

    test('nominal bertitik tetap terbaca', () async {
      expect((await one('Eka 150.000')).amount, 150000);
      expect((await one('Eka Rp 15.000')).amount, 15000);
    });

    test('judul daftar ditandai perlu dicek', () async {
      expect((await one('Daftar hadir Rabu')).needsReview, isTrue);
      expect((await one('Rina Wulandari')).needsReview, isFalse);
    });
  });
}
