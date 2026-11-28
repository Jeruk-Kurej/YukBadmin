import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/core/widgets/photo.dart';
import 'package:yukbadmin/features/club/data/club_models.dart';
import 'package:yukbadmin/features/club/data/club_repository.dart';
import 'package:yukbadmin/features/club/state/club_providers.dart';
import 'package:yukbadmin/features/manage/data/manage_codec.dart';
import 'package:yukbadmin/features/manage/data/manage_models.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/features/club/pages/session_ticket.dart';
import 'package:yukbadmin/main.dart';

/// Senin, 16 November 2026 pukul 10.00. Sesi PB Smash Surabaya berikutnya
/// Rabu 18 November 19.00.
final _now = DateTime(2026, 11, 16, 10);

class _NoMemberships implements MembershipRepository {
  @override
  List<Membership> forUser(String email, DateTime now) => const [];
}

class _FakePicker implements PhotoPicker {
  var _n = 0;

  @override
  Future<String?> pick(PhotoSource source) async => '/bukti-${++_n}.jpg';
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
  about: '',
  rules: [],
  manager: PbManager(name: 'Bryan Carlie', whatsapp: '6281234567890'),
  openForNewMembers: true,
  artSeed: 0,
  paymentInfo: 'Transfer BCA 1234567890 a.n. Bryan',
);

void main() {
  group('keanggotaan contoh', () {
    test('akun demo jadi member PB Smash dengan satu iuran belum dibayar', () {
      final list = const SeedMembershipRepository().forUser(
        SeedMembershipRepository.demoEmail,
        _now,
      );
      final m = list.single;
      expect(m.pbId, 'pb-smash-surabaya');
      expect(m.upcoming(_now).map((e) => e.start), [
        DateTime(2026, 11, 18, 19),
        DateTime(2026, 11, 21, 8),
        DateTime(2026, 11, 25, 19),
      ]);
      expect(m.unpaidDues().single.$1.start, DateTime(2026, 11, 14, 8));
      expect(m.unansweredCount(_now), 3);
      // Hanya jumlah yang ikut, tanpa nama member lain.
      expect(m.upcoming(_now).first.goingCount, 8);
    });
  });

  group('konfirmasi, bukti transfer, dan pengurus', () {
    late ProviderContainer c;
    ManageNotifier notifier() => c.read(manageProvider.notifier);
    ManageState state() => c.read(manageProvider);

    setUp(() {
      c = ProviderContainer(
        overrides: [nowProvider.overrideWithValue(() => _now)],
      );
      notifier().registerPb(_pb);
    });
    tearDown(() => c.dispose());

    test('konfirmasi ikut dihitung dan terhapus bersama member', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final bella = notifier().addMember(name: 'Bella', type: MemberType.tetap);
      final e = state().events.single;
      notifier().setRsvp(e.id, andi.id, Rsvp.ikut);
      notifier().setRsvp(e.id, bella.id, Rsvp.tidak);
      expect(state().events.single.goingCount, 1);
      expect(state().events.single.notGoingCount, 1);

      notifier().removeMember(andi.id);
      expect(state().events.single.rsvps.keys, [bella.id]);
    });

    test(
      'bukti sebelum kehadiran membuat iuran dan tetap ada setelah dicatat',
      () {
        final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
        final e = state().events.single;
        notifier().submitProof(e.id, andi.id, '/bukti.jpg');
        var due = state().events.single.dues[andi.id]!;
        expect(due.amount, 150000);
        expect(due.awaitingCheck, isTrue);
        expect(state().proofsToCheck, 1);
        expect(state().events.single.remindableCount, 0);

        // Andi tidak dicentang hadir, tapi buktinya tidak boleh hilang.
        notifier().saveAttendance(e.id, {});
        due = state().events.single.dues[andi.id]!;
        expect(due.proof?.path, '/bukti.jpg');
      },
    );

    test('bukti ditolak dengan alasan, dikirim ulang, lalu disetujui', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final e = state().events.single;
      notifier().saveAttendance(e.id, {andi.id});
      notifier().submitProof(e.id, andi.id, '/bukti-1.jpg');
      notifier().rejectProof(e.id, andi.id, ' Foto tidak terbaca ');
      var due = state().events.single.dues[andi.id]!;
      expect(due.proof?.status, ProofStatus.ditolak);
      expect(due.proof?.reason, 'Foto tidak terbaca');
      expect(due.paid, isFalse);
      expect(state().events.single.remindableCount, 1);

      notifier().submitProof(e.id, andi.id, '/bukti-2.jpg');
      notifier().approveProof(e.id, andi.id);
      due = state().events.single.dues[andi.id]!;
      expect(due.paid, isTrue);
      expect(due.proof?.status, ProofStatus.disetujui);
      expect(due.proof?.path, '/bukti-2.jpg');
    });

    test('pengurus diundang lalu dikeluarkan', () {
      final sari = notifier().inviteCoManager(
        name: ' Sari Dewi ',
        whatsapp: '6281311112222',
      );
      expect(state().coManagers.single.name, 'Sari Dewi');
      expect(sari.status, CoManagerStatus.diundang);
      notifier().removeCoManager(sari.id);
      expect(state().coManagers, isEmpty);
    });

    test('semua data baru tersimpan dan terbaca lagi dari JSON', () {
      final andi = notifier().addMember(name: 'Andi', type: MemberType.tetap);
      final e = state().events.single;
      notifier().setRsvp(e.id, andi.id, Rsvp.ikut);
      notifier().submitProof(e.id, andi.id, '/bukti.jpg');
      notifier().rejectProof(e.id, andi.id, 'Nominal tidak sesuai');
      notifier().inviteCoManager(name: 'Sari', whatsapp: '6281311112222');

      final restored = manageStateFromJson(
        jsonDecode(jsonEncode(manageStateToJson(state()))),
      );
      final event = restored.events.single;
      expect(event.rsvps[andi.id], Rsvp.ikut);
      expect(event.dues[andi.id]!.proof?.reason, 'Nominal tidak sesuai');
      expect(event.dues[andi.id]!.proof?.sentAt, _now);
      expect(restored.coManagers.single.whatsapp, '6281311112222');
      expect(restored.pb!.paymentInfo, 'Transfer BCA 1234567890 a.n. Bryan');
    });
  });

  group('cache PB-ku', () {
    ProviderContainer open(LocalStore store) {
      final c = ProviderContainer(
        overrides: [
          localStoreProvider.overrideWithValue(store),
          nowProvider.overrideWithValue(() => _now),
        ],
      );
      c.read(sessionProvider.notifier).signInDemo();
      return c;
    }

    test('jawaban tetap ada setelah app dibuka ulang', () {
      final store = MemoryLocalStore();
      final first = open(store);
      final event = first.read(membershipProvider).single.upcoming(_now).first;
      first
          .read(membershipProvider.notifier)
          .setRsvp('pb-smash-surabaya', event.id, Rsvp.ikut);
      first.dispose();

      final second = open(store);
      final restored = second.read(membershipProvider).single;
      expect(restored.eventById(event.id)!.rsvps['m-saya'], Rsvp.ikut);
      second.dispose();
    });

    test('cache milik akun lain diabaikan', () {
      final store = MemoryLocalStore({
        CacheKeys.membership: jsonEncode({
          'email': 'lain@contoh.id',
          'items': [],
        }),
      });
      final c = open(store);
      expect(c.read(membershipProvider), hasLength(1));
      c.dispose();
    });

    test('keluar akun mengosongkan PB-ku', () {
      final c = open(MemoryLocalStore());
      expect(c.read(membershipProvider), isNotEmpty);
      c.read(sessionProvider.notifier).signOut();
      expect(c.read(membershipProvider), isEmpty);
      c.dispose();
    });
  });

  group('di layar', () {
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
            nowProvider.overrideWithValue(() => _now),
            photoPickerProvider.overrideWithValue(_FakePicker()),
          ],
          child: const YukBadminApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      c.read(sessionProvider.notifier).signInDemo();
      if (withPb) c.read(manageProvider.notifier).registerPb(_pb);
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

    testWidgets('member menjawab ikut dan mengirim bukti dari PB-ku', (
      tester,
    ) async {
      final c = await start(tester);
      // Jadwalmu menampilkan semua sesi mendatang, bukan hanya yang pertama.
      final upcoming = c
          .read(membershipProvider)
          .single
          .upcoming(c.read(nowProvider)())
          .length;
      expect(upcoming, greaterThan(1));
      expect(find.byType(SessionTicket), findsNWidgets(upcoming));
      // Tiket Beranda tanpa tombol: seluruh tiket membuka PB-ku untuk
      // menjawab ikut, lalu tiket menampilkan status tagihannya.
      expect(find.text('8 ikut'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Ikut'), findsNothing);
      await tap(tester, find.byType(SessionTicket).first);
      expect(find.byType(SessionTicket), findsNothing);
      await tap(tester, find.text('Ikut').first);

      final pbId = c.read(membershipProvider).single.pbId;
      c.read(routerProvider).go('/beranda');
      await tester.pumpAndSettle();
      expect(find.text('9 ikut'), findsOneWidget);
      expect(find.text('Bayar Rp150rb'), findsOneWidget);

      c.read(routerProvider).push('/pb-ku/$pbId');
      await tester.pumpAndSettle();
      // Ikut sesi berikutnya langsung menambah tagihan (bayar sebelum main).
      expect(find.text('Kirim bukti transfer'), findsNWidgets(2));
      await tap(tester, find.text('Kirim bukti transfer').first);
      await tap(tester, find.text('Pilih dari galeri'));
      expect(find.text('Menunggu dicek'), findsOneWidget);
      final dues = c.read(membershipProvider).single.unpaidDues();
      expect(dues.first.$2.proof?.path, '/bukti-1.jpg');
      expect(dues.last.$2.proof, isNull);
      // Member tidak punya tombol untuk mengubah iuran.
      expect(find.text('Tandai lunas'), findsNothing);
    });

    testWidgets('PB-ku kosong menawarkan cari PB', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            membershipRepositoryProvider.overrideWithValue(_NoMemberships()),
          ],
          child: const YukBadminApp(),
        ),
      );
      final c = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      c.read(sessionProvider.notifier).signInDemo();
      await tester.pumpAndSettle();
      expect(find.textContaining('Jawab'), findsNothing);

      c.read(routerProvider).push('/pb-ku');
      await tester.pumpAndSettle();
      expect(find.text('Belum jadi member PB mana pun'), findsOneWidget);
      await tap(tester, find.text('Cari PB').last);
      expect(find.text('PB Kok Kuning'), findsOneWidget);

      c.read(routerProvider).push('/pb-ku/pb-smash-surabaya');
      await tester.pumpAndSettle();
      expect(find.text('Kamu tidak tercatat di PB ini'), findsOneWidget);
    });

    testWidgets(
      'pengurus melihat konfirmasi, memeriksa bukti, menolak, lalu menyetujui',
      (tester) async {
        final c = await start(tester, withPb: true);
        final andi = c
            .read(manageProvider.notifier)
            .addMember(name: 'Andi Pratama', type: MemberType.tetap);
        final event = c.read(manageProvider).events.single;

        // Pratinjau sebagai member: jawab ikut.
        c.read(routerProvider).push('/kelola/lihat-member');
        await tester.pumpAndSettle();
        await tap(tester, find.text('Andi Pratama'));
        expect(find.text('Sebagai Andi'), findsOneWidget);
        expect(find.text('Transfer BCA 1234567890 a.n. Bryan'), findsOneWidget);
        await tap(tester, find.text('Ikut'));
        expect(c.read(manageProvider).events.single.rsvps[andi.id], Rsvp.ikut);

        // Jadwal menampilkan jumlah konfirmasi, kehadiran sudah dicentang.
        c.read(routerProvider).go('/kelola/jadwal');
        await tester.pumpAndSettle();
        expect(find.text('Konfirmasi: 1 ikut'), findsOneWidget);
        c.read(routerProvider).push('/sesi/${event.id}/kehadiran');
        await tester.pumpAndSettle();
        expect(find.text('Simpan 1 hadir'), findsOneWidget);
        await tap(tester, find.text('Simpan 1 hadir'));

        // Member mengirim bukti; pengurus mengeceknya dari halaman iuran.
        c
            .read(manageProvider.notifier)
            .submitProof(event.id, andi.id, '/b.jpg');
        await tester.pumpAndSettle();
        expect(find.text('Cek bukti'), findsOneWidget);
        expect(find.textContaining('Kirim pengingat'), findsNothing);
        await tap(tester, find.text('Cek bukti'));
        expect(find.text('Cek bukti transfer'), findsOneWidget);

        await tap(tester, find.text('Tolak'));
        await tap(tester, find.text('Tolak bukti'));
        expect(
          find.text(
            'Tulis alasannya supaya member tahu apa yang perlu diperbaiki.',
          ),
          findsOneWidget,
        );
        await tap(tester, find.text('Foto tidak terbaca'));
        await tap(tester, find.text('Tolak bukti'));
        var due = c.read(manageProvider).events.single.dues[andi.id]!;
        expect(due.proof?.status, ProofStatus.ditolak);
        expect(find.text('Kirim pengingat (1)'), findsOneWidget);

        c
            .read(manageProvider.notifier)
            .submitProof(event.id, andi.id, '/c.jpg');
        await tester.pumpAndSettle();
        await tap(tester, find.text('Cek bukti'));
        await tap(tester, find.text('Setujui, lunas'));
        due = c.read(manageProvider).events.single.dues[andi.id]!;
        expect(due.paid, isTrue);
        expect(find.text('Lunas'), findsOneWidget);
      },
    );

    testWidgets('undang pengurus dengan validasi, lalu batalkan undangan', (
      tester,
    ) async {
      final c = await start(tester, withPb: true);
      c.read(routerProvider).push('/kelola/pengurus');
      await tester.pumpAndSettle();
      expect(find.text('Kamu · Pemilik'), findsOneWidget);

      await tap(tester, find.text('Undang pengurus'));
      await tap(tester, find.text('Kirim undangan'));
      expect(find.text('Isi nama pengurus, minimal 2 huruf.'), findsOneWidget);

      Finder field(int i) => find.byType(TextFormField).at(i);
      await tester.enterText(field(0), 'Sari Dewi');
      await tester.pumpAndSettle();
      await tester.enterText(field(1), '0812 3456 7890');
      await tap(tester, find.text('Kirim undangan'));
      expect(
        find.text('Nomor ini sudah terdaftar sebagai pengurus.'),
        findsOneWidget,
      );

      await tester.enterText(field(1), '0813 1111 2222');
      await tap(tester, find.text('Kirim undangan'));
      expect(find.text('Menunggu diterima'), findsOneWidget);
      expect(c.read(manageProvider).coManagers.single.name, 'Sari Dewi');

      await tap(tester, find.byTooltip('Batalkan undangan Sari Dewi'));
      expect(find.text('Batalkan undangan Sari Dewi?'), findsOneWidget);
      await tap(tester, find.text('Batalkan undangan'));
      expect(c.read(manageProvider).coManagers, isEmpty);
    });

    testWidgets('layar baru di layar kecil dan teks besar tidak meluber', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await start(tester, size: const Size(320, 640), withPb: true);
      final n = c.read(manageProvider.notifier);
      final andi = n.addMember(name: 'Andi Pratama', type: MemberType.tetap);
      final event = c.read(manageProvider).events.single;
      n.saveAttendance(event.id, {andi.id});
      n.submitProof(event.id, andi.id, '/b.jpg');
      n.inviteCoManager(name: 'Sari Dewi', whatsapp: '6281311112222');

      final router = c.read(routerProvider);
      for (final path in [
        '/pb-ku',
        '/pb-ku/pb-smash-surabaya',
        '/kelola/beranda',
        '/kelola/pengurus',
        '/kelola/lihat-member',
        '/kelola/lihat-member/${andi.id}',
        '/kelola/jadwal',
        '/kelola/profil',
      ]) {
        router.go(path);
        await tester.pumpAndSettle();
      }
      router.go('/kelola/iuran');
      router.push('/sesi/${event.id}/iuran');
      await tester.pumpAndSettle();
      await tap(tester, find.text('Cek bukti'));
      await tap(tester, find.text('Tolak'));
      expect(find.text('Tolak bukti'), findsOneWidget);
    });
  });
}
