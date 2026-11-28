import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/features/manage/data/import_parser.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

import 'test_helpers.dart';

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
  memberTypes: {MemberType.tetap, MemberType.insidental},
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
  group('nomor WhatsApp', () {
    test('dinormalisasi ke format 62', () {
      expect(normalizeWhatsapp('0812 3456 7890'), '6281234567890');
      expect(normalizeWhatsapp('+62 812-3456-7890'), '6281234567890');
      expect(normalizeWhatsapp('81234567890'), '6281234567890');
    });

    test('nomor yang bukan ponsel ditolak', () {
      expect(normalizeWhatsapp(''), isNull);
      expect(normalizeWhatsapp('12345'), isNull);
      expect(normalizeWhatsapp('0311234567'), isNull);
    });

    test('ditampilkan lagi dalam format lokal', () {
      expect(displayWhatsapp('6281234567890'), '0812 3456 7890');
    });
  });

  group('RuleBasedNoteParser', () {
    const parser = RuleBasedNoteParser();

    test('membaca nama, jenis, nominal, dan status bayar', () async {
      final rows = await parser.parse(
        '1. Andi Pratama - tetap - 300rb lunas\n'
        '2. Bella Kusuma - tetap - 300rb belum\n'
        '3. Cahyo Wibowo (insidental) 150.000\n',
      );
      expect(rows.map((r) => r.name), [
        'Andi Pratama',
        'Bella Kusuma',
        'Cahyo Wibowo',
      ]);
      expect(rows[0].type, MemberType.tetap);
      expect(rows[0].amount, 300000);
      expect(rows[0].paid, isTrue);
      expect(rows[1].paid, isFalse);
      expect(rows[2].type, MemberType.insidental);
      expect(rows[2].amount, 150000);
      expect(rows[2].paid, isNull);
      expect(rows.any((r) => r.needsReview), isFalse);
    });

    test('nama meragukan dan nama ganda ditandai perlu dicek', () async {
      final rows = await parser.parse(
        'Eko S.?\nDewi Anggraini\ndewi anggraini',
      );
      expect(rows[0].needsReview, isTrue);
      expect(rows[1].needsReview, isFalse);
      expect(rows[2].needsReview, isTrue);
    });

    test('awalan ekspor chat WhatsApp dibuang', () async {
      final rows = await parser.parse(
        '[12/11/26, 19.02] Pak Hendra: Fajar Nugroho lunas',
      );
      expect(rows.single.name, 'Fajar Nugroho');
      expect(rows.single.paid, isTrue);
    });

    test('baris kosong dan baris tanpa nama dilewati', () async {
      final rows = await parser.parse('\n\n12/11/2026\n150.000\n   \n');
      expect(rows, isEmpty);
    });
  });

  group('ManageNotifier', () {
    late ProviderContainer container;
    ManageNotifier notifier() => container.read(manageProvider.notifier);
    ManageState state() => container.read(manageProvider);

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // Senin, 16 November 2026 pukul 10.00.
          nowProvider.overrideWithValue(() => DateTime(2026, 11, 16, 10)),
        ],
      );
      addTearDown(container.dispose);
      notifier().registerPb(_pb);
    });

    test('mendaftarkan PB menyiapkan sesi di hari jadwal berikutnya', () {
      final event = state().events.single;
      expect(event.start, DateTime(2026, 11, 18, 19));
      expect(event.durationMinutes, 180);
      expect(event.attendanceSaved, isFalse);
    });

    test('jumlah member di profil PB mengikuti daftar member', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      notifier().addMember(name: 'Bella', type: MemberType.insidental);
      expect(state().pb!.memberCount, 2);
      notifier().removeMember(andi.id);
      expect(state().pb!.memberCount, 1);
    });

    test('menyimpan kehadiran membuat iuran untuk yang hadir saja', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final bella = notifier().addMember(name: 'Bella', type: MemberType.tetap);
      final eventId = state().events.single.id;

      notifier().saveAttendance(eventId, {andi.id});
      var event = state().eventById(eventId)!;
      expect(event.dues.keys, [andi.id]);
      expect(event.dues[andi.id]!.amount, 150000);
      expect(event.outstanding, 150000);

      notifier().setDue(
        eventId,
        andi.id,
        const Due(amount: 175000, paid: true),
      );
      // Kehadiran diubah: Andi batal hadir tapi sudah bayar, Bella hadir.
      notifier().saveAttendance(eventId, {bella.id});
      event = state().eventById(eventId)!;
      expect(
        event.dues[andi.id]!.paid,
        isTrue,
        reason: 'yang lunas tidak hilang',
      );
      expect(event.dues[bella.id]!.paid, isFalse);
      expect(event.collected, 175000);
      expect(event.unpaidCount, 1);
      expect(state().paidPercent, 50);
    });

    test('menghapus member ikut menghapus kehadiran dan iurannya', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final eventId = state().events.single.id;
      notifier().saveAttendance(eventId, {andi.id});
      notifier().removeMember(andi.id);
      final event = state().eventById(eventId)!;
      expect(event.attendees, isEmpty);
      expect(event.dues, isEmpty);
    });

    test('bayar di muka tersimpan dan tidak hilang saat kehadiran dicatat', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final bella = notifier().addMember(name: 'Bella', type: MemberType.tetap);
      final eventId = state().events.single.id;

      notifier().setDue(
        eventId,
        andi.id,
        const Due(amount: 150000, paid: true),
      );
      notifier().saveAttendance(eventId, {bella.id});
      final event = state().eventById(eventId)!;
      expect(event.dues[andi.id]!.paid, isTrue);
      expect(event.dues[bella.id]!.paid, isFalse);

      notifier().removeDue(eventId, andi.id);
      expect(state().eventById(eventId)!.dues.containsKey(andi.id), isFalse);
    });

    test('impor melewati nama yang sudah ada', () {
      notifier().addMember(name: 'Andi Pratama', type: MemberType.tetap);
      final added = notifier().importRows(const [
        ImportRow(name: 'andi pratama', type: MemberType.tetap),
        ImportRow(name: 'Bella Kusuma', type: MemberType.insidental),
      ]);
      expect(added, 1);
      expect(state().members.length, 2);
    });

    test('PB milik pengguna muncul di daftar Cari PB', () async {
      final list = await container.read(pbListProvider.future);
      expect(list.first.id, 'pb-milikku');
    });
  });

  group('alur pengurus di layar', () {
    Future<void> openAccount(
      WidgetTester tester, {
      Size size = const Size(390, 844),
    }) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: YukBadminApp()));
      await tester.pumpAndSettle();
      await signInWithEmail(tester);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    testWidgets('form pendaftaran menolak isian kosong', (tester) async {
      await openAccount(tester);
      await tapVisible(tester, find.text('Daftarkan').first);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Isi nama PB, minimal 3 huruf.'), findsOneWidget);
      final phoneError = find.text(
        'Isi nomor ponsel yang benar, misalnya 0812 3456 7890.',
      );
      await tester.scrollUntilVisible(
        phoneError,
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(phoneError, findsOneWidget);
    });

    testWidgets('daftar PB, tambah member, catat hadir, tandai lunas', (
      tester,
    ) async {
      await openAccount(tester);
      await tapVisible(tester, find.text('Daftarkan').first);

      Finder field(String hint) => find.widgetWithText(TextFormField, hint);
      await tester.enterText(field('PB Smash Surabaya'), 'PB Uji Coba');
      await tester.enterText(field('GOR Kertajaya'), 'GOR Uji');
      await tester.enterText(field('Gubeng'), 'Gubeng');
      await tester.scrollUntilVisible(
        field('0812 3456 7890'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('0812 3456 7890'), '0812 3456 7890');
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      // Langkah 2: tanpa level dan iuran harus ditolak.
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih minimal satu level.'), findsOneWidget);

      await tester.tap(find.text('D'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('B'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        field('150000'),
        120,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(field('150000'), '150000');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Periksa data PB'), findsOneWidget);
      expect(find.textContaining('Level D–B'), findsOneWidget);
      await tapVisible(tester, find.text('Daftarkan PB'));

      // Dashboard.
      expect(find.text('Pengurus PB'), findsOneWidget);
      expect(find.text('PB Uji Coba'), findsOneWidget);
      expect(find.text('Punya catatan member lama?'), findsOneWidget);

      // Tambah member lewat tab Member.
      await tester.tap(find.text('Member').last);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada member'), findsOneWidget);
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Andi Pratama');
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Andi Pratama'), findsOneWidget);
      expect(find.text('Semua 1'), findsOneWidget);

      // Catat kehadiran dari tab Jadwal.
      await tester.tap(find.text('Jadwal'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Catat kehadiran'));
      expect(find.text('Simpan 0 hadir'), findsOneWidget);
      await tester.tap(find.text('Andi Pratama'));
      await tester.pumpAndSettle();
      expect(find.text('Simpan 1 hadir'), findsOneWidget);
      await tester.tap(find.text('Simpan 1 hadir'));
      await tester.pumpAndSettle();

      // Iuran sesi.
      expect(find.text('Iuran sesi'), findsOneWidget);
      expect(find.text('Kirim pengingat (1)'), findsOneWidget);
      await tester.tap(find.text('Tandai lunas'));
      await tester.pumpAndSettle();
      expect(find.text('Lunas'), findsOneWidget);
      expect(find.text('Kirim pengingat (1)'), findsNothing);

      // Salah pencet: dibatalkan lewat snackbar.
      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Tandai lunas'), findsOneWidget);

      // Menandai lunas lagi, lalu membatalkan lewat tombol Lunas butuh konfirmasi.
      await tester.tap(find.text('Tandai lunas'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lunas'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan status lunas?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();
      expect(find.text('Lunas'), findsOneWidget);
    });

    testWidgets('impor catatan menahan simpan sampai baris dicek', (
      tester,
    ) async {
      await openAccount(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      container.read(manageProvider.notifier).registerPb(_pb);
      container.read(routerProvider).push('/daftar-pb');
      await tester.pumpAndSettle();
      // Sudah punya PB, jadi diarahkan ke dashboard.
      expect(find.text('Pengurus PB'), findsOneWidget);

      await tapVisible(tester, find.text('Impor catatan').first);
      await tester.tap(find.text('Baca catatan'));
      await tester.pumpAndSettle();
      expect(
        find.text('Tempel catatanmu dulu, satu nama per baris.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Isi dengan contoh'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Baca catatan'));
      await tester.pumpAndSettle();
      expect(find.text('Periksa hasil'), findsOneWidget);
      expect(find.text('Semua 5'), findsOneWidget);
      expect(find.text('Perlu dicek 1'), findsOneWidget);
      expect(find.text('Cek 1 baris dulu'), findsOneWidget);

      // Buang baris yang meragukan, lalu simpan.
      await tapVisible(tester, find.byTooltip('Buang Eko S.'));
      expect(find.text('Simpan 4 member ke PB'), findsOneWidget);
      await tester.tap(find.text('Simpan 4 member ke PB'));
      await tester.pumpAndSettle();
      expect(find.text('Semua 4'), findsOneWidget);
      expect(container.read(manageProvider).members.length, 4);
    });
  });
}
