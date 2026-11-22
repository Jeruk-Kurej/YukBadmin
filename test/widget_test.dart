import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/core/widgets/yb_widgets.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/pb_repository.dart';

void main() {
  late List<Pb> all;

  setUpAll(() async {
    all = await const SeedPbRepository().fetchAll();
  });

  List<String> idsFor(PbFilter filter) =>
      all.where(filter.matches).map((pb) => pb.id).toList();

  group('PbFilter', () {
    test('tanpa filter menampilkan semua PB', () {
      expect(idsFor(const PbFilter()).length, all.length);
      expect(const PbFilter().activeCount, 0);
    });

    test(
      'kata kunci mencocokkan nama dan kecamatan, tanpa peduli huruf besar',
      () {
        expect(idsFor(const PbFilter(query: 'RUNGKUT')), ['pb-kok-kuning']);
        expect(idsFor(const PbFilter(query: 'rajawali')), ['pb-rajawali']);
      },
    );

    test('level menyaring PB yang rentangnya memuat level itu', () {
      final ids = idsFor(const PbFilter(levels: {Level.s}));
      expect(ids, ['pb-garuda-muda']);
    });

    test('jenis member insidental membuang PB khusus member tetap', () {
      final ids = idsFor(const PbFilter(memberType: MemberType.insidental));
      expect(ids, isNot(contains('pb-rajawali')));
      expect(ids, contains('pb-kok-kuning'));
    });

    test('rentang biaya memakai iuran per sesi', () {
      final ids = idsFor(const PbFilter(maxFee: 75000));
      expect(
        ids,
        unorderedEquals(['pb-mulyosari-ceria', 'pb-tenggilis-smash']),
      );
    });

    test('akhir pekan dan waktu malam digabung dengan DAN', () {
      final weekend = idsFor(const PbFilter(weekendOnly: true));
      expect(weekend, contains('pb-smash-surabaya'));
      expect(weekend, isNot(contains('pb-rajawali')));

      final night = idsFor(const PbFilter(dayParts: {DayPart.malam}));
      expect(night, contains('pb-rajawali'));
      expect(night, isNot(contains('pb-kok-kuning')));
    });

    test(
      'hari kerja dan akhir pekan sekaligus berarti tidak menyaring hari',
      () {
        const both = PbFilter(weekdaysOnly: true, weekendOnly: true);
        expect(idsFor(both).length, all.length);
      },
    );

    test('activeCount menghitung kelompok filter, bukan kata kunci', () {
      const filter = PbFilter(
        query: 'pb',
        levels: {Level.d, Level.c},
        memberType: MemberType.tetap,
        maxFee: 175000,
      );
      expect(filter.activeCount, 3);
    });
  });

  group('PlayerPreferences', () {
    test('PB yang cocok level dan hari mendapat skor lebih tinggi', () {
      const prefs = PlayerPreferences(level: Level.f, weekdays: {6});
      final kokKuning = all.firstWhere((pb) => pb.id == 'pb-kok-kuning');
      final garuda = all.firstWhere((pb) => pb.id == 'pb-garuda-muda');
      expect(prefs.scoreFor(kokKuning), greaterThan(prefs.scoreFor(garuda)));
    });
  });

  group('format', () {
    test('rupiah', () {
      expect(formatRupiah(150000), 'Rp150.000');
      expect(formatRupiahShort(150000), 'Rp150rb');
      expect(formatRupiahShort(0), 'Rp0');
    });

    test('jam sesi dan inisial pengurus', () {
      final pb = all.firstWhere((pb) => pb.id == 'pb-smash-surabaya');
      expect(pb.firstSession.timeRange, '19.00–22.00');
      expect(pb.levelRange, 'D–B');
      expect(pb.manager.initials, 'HE');
    });
  });
}
