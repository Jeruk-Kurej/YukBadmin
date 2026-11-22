import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/features/gear/data/advisor.dart';
import 'package:yukbadmin/features/gear/data/gear_models.dart';
import 'package:yukbadmin/features/gear/data/gear_repository.dart';
import 'package:yukbadmin/main.dart';

void main() {
  late List<Product> products;
  const advisor = GearAdvisor();

  setUpAll(() async {
    products = await const SeedGearRepository().fetchProducts();
  });

  group('GearAdvisor raket', () {
    test(
      'pemula yang belum tahu gaya main mendapat raket ringan dan seimbang',
      () {
        final result = advisor.rackets(
          products,
          skill: SkillGroup.pemula,
          style: PlayStyle.belumTahu,
          position: CourtPosition.belumTahu,
        );
        expect(result.first.product.id, 'p-falcon-80');
        expect(result.first.matched, result.first.total);
        expect(
          result.first.total,
          3,
          reason: 'posisi belum tahu tidak dihitung',
        );
      },
    );

    test('pemain mahir yang menyerang diarahkan ke raket berat di kepala', () {
      final result = advisor.rackets(
        products,
        skill: SkillGroup.mahir,
        style: PlayStyle.menyerang,
        position: CourtPosition.belakang,
      );
      final top = result.first.product.racket!;
      expect(top.balance, RacketBalance.headHeavy);
      expect(result.first.total, 4);
    });

    test('setiap kriteria punya alasan yang bisa dibaca', () {
      final result = advisor.rackets(
        products,
        skill: SkillGroup.pemula,
        style: PlayStyle.bertahan,
        position: CourtPosition.depan,
      );
      for (final s in result) {
        expect(s.reasons, hasLength(s.total));
        expect(s.reasons.every((r) => r.text.isNotEmpty), isTrue);
      }
      final titan = result.firstWhere((s) => s.product.id == 'p-titan-pro');
      expect(titan.matched, lessThan(titan.total));
    });

    test('saran senar mengikuti level dan memilih yang stoknya ada', () {
      final pemula = advisor.rackets(
        products,
        skill: SkillGroup.pemula,
        style: PlayStyle.menyerang,
        position: CourtPosition.belumTahu,
      );
      final tip = pemula.first.stringTip!;
      expect(tip.type, StringType.tebal);
      expect(tip.tension, '20–22 lbs');
      expect(tip.product!.inStock, isTrue);

      final mahir = advisor.rackets(
        products,
        skill: SkillGroup.mahir,
        style: PlayStyle.menyerang,
        position: CourtPosition.belumTahu,
      );
      expect(mahir.first.stringTip!.type, StringType.tipis);
    });

    test('yang stoknya ada diutamakan kalau sama cocoknya', () {
      final result = advisor.rackets(
        products,
        skill: SkillGroup.mahir,
        style: PlayStyle.menyerang,
        position: CourtPosition.belumTahu,
      );
      final perfect = result.where((s) => s.matched == s.total).toList();
      final firstOut = perfect.indexWhere((s) => !s.product.inStock);
      final lastIn = perfect.lastIndexWhere((s) => s.product.inStock);
      if (firstOut != -1) expect(lastIn, lessThan(firstOut));
    });
  });

  group('GearAdvisor sepatu', () {
    test('hanya sepatu dengan ukuran yang dipilih', () {
      final size41 = advisor.shoes(products, size: 41);
      expect(size41.map((s) => s.product.id), [
        'p-langkah-lite',
        'p-gesit-court-pro',
      ]);
      expect(
        advisor.shoes(products, size: 44).single.product.id,
        'p-gesit-court-pro',
      );
      expect(advisor.shoes(products, size: 46), isEmpty);
    });
  });

  group('alur perlengkapan di layar', () {
    Future<void> signIn(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: YukBadminApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
    }

    Future<void> tapVisible(WidgetTester tester, Finder finder) async {
      // Item di ListView yang belum terlihat belum dibangun, jadi gulir dulu.
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

    testWidgets('feed, saring kategori, detail produk, lalu detail toko', (
      tester,
    ) async {
      await signIn(tester);
      await tester.tap(find.text('Perlengkapan'));
      await tester.pumpAndSettle();
      expect(find.text('Raket Falcon 80'), findsOneWidget);

      await tester.tap(find.text('Senar'));
      await tester.pumpAndSettle();
      expect(find.text('Raket Falcon 80'), findsNothing);
      expect(find.text('Senar Lincah 66'), findsOneWidget);

      await tester.tap(find.text('Senar Lincah 66'));
      await tester.pumpAndSettle();
      expect(find.text('Detail produk'), findsOneWidget);
      expect(find.text('Habis'), findsOneWidget);
      expect(find.text('Tanya kapan ada lagi'), findsOneWidget);

      await tapVisible(tester, find.text('Toko Gesit Sport'));
      expect(find.text('Buka di Google Maps'), findsOneWidget);
      expect(find.textContaining('Jl. Raya Nginden No. 12'), findsOneWidget);
    });

    testWidgets('saran raket menampilkan alasan dan saran senar', (
      tester,
    ) async {
      await signIn(tester);
      await tester.tap(find.text('Perlengkapan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bingung pilih raket atau sepatu?'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Kenapa saran ini?'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // Penjelasan dibuka di sheet, tidak memenuhi halaman.
      await tester.tap(find.text('Kenapa saran ini?'));
      await tester.pumpAndSettle();
      expect(find.text('Cara saran ini dibuat'), findsOneWidget);
      expect(find.text('Titik berat'), findsOneWidget);
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lihat saran'));
      await tester.pumpAndSettle();
      expect(find.text('Hasil saran'), findsOneWidget);
      expect(find.text('Paling cocok'), findsOneWidget);
      expect(find.text('Alasannya'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Senar dan tarikan untuk raketmu'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('tarikan 20–22 lbs'), findsOneWidget);
    });

    testWidgets('saran sepatu wajib pilih ukuran', (tester) async {
      await signIn(tester);
      await tester.tap(find.text('Perlengkapan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bingung pilih raket atau sepatu?'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sepatu'));
      await tester.pumpAndSettle();
      expect(find.text('Ukuran sepatumu (EU)'), findsOneWidget);

      await tester.tap(find.text('Lihat saran'));
      await tester.pumpAndSettle();
      expect(find.text('Pilih ukuran sepatumu dulu.'), findsOneWidget);

      await tapVisible(tester, find.text('46'));
      await tester.tap(find.text('Lihat saran'));
      await tester.pumpAndSettle();
      expect(find.text('Belum ada sepatu ukuran 46'), findsOneWidget);
    });

    testWidgets('daftar toko, tambah produk, lalu muncul di feed pemain', (
      tester,
    ) async {
      await signIn(tester);
      await tester.tap(find.text('Akun'));
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('Daftarkan toko'));

      Finder field(String hint) => find.widgetWithText(TextFormField, hint);
      Future<void> type(String hint, String text) async {
        await tester.ensureVisible(field(hint));
        await tester.pumpAndSettle();
        await tester.enterText(field(hint), text);
        await tester.pumpAndSettle();
      }

      await type('Toko Gesit Sport', 'Toko Uji Raket');
      await type('0821 5555 0101', '0821 9999 0000');
      await type(
        'Jl. Raya Nginden No. 12, Surabaya',
        'Jl. Uji Coba No. 1, Surabaya',
      );
      await type('Sukolilo', 'Gubeng');
      await type('Senin–Sabtu 09.00–20.00', 'Setiap hari 09.00–21.00');
      await tester.tap(find.text('Daftarkan toko').last);
      await tester.pumpAndSettle();

      expect(find.text('Belum ada produk'), findsOneWidget);
      await tester.tap(find.text('Tambah'));
      await tester.pumpAndSettle();
      await type('Raket Falcon 80', 'Raket Uji Ringan');
      await type('1250000', '500000');

      // Raket tanpa spesifikasi ditolak.
      await tester.tap(find.text('Simpan produk'));
      await tester.pumpAndSettle();
      expect(
        find.text('Lengkapi berat, titik berat, dan kelenturan raket.'),
        findsOneWidget,
      );

      await tapVisible(tester, find.text('5U · 75–79 gram'));
      await tapVisible(tester, find.text('Seimbang'));
      await tapVisible(tester, find.text('Lentur'));
      await tester.tap(find.text('Simpan produk'));
      await tester.pumpAndSettle();
      expect(find.text('Raket Uji Ringan'), findsOneWidget);

      // Ganti stok langsung dari daftar.
      await tester.tap(find.text('Ready'));
      await tester.pumpAndSettle();
      expect(find.text('Habis'), findsOneWidget);

      await tapVisible(tester, find.text('Beralih ke mode pemain'));
      await tester.tap(find.text('Perlengkapan'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'uji');
      await tester.pumpAndSettle();
      expect(find.text('Raket Uji Ringan'), findsOneWidget);
    });

    testWidgets('layar kecil dan teks besar tidak meluber', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: YukBadminApp()));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masuk dengan Google'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perlengkapan'));
      await tester.pumpAndSettle();
      Future<void> scrollTap(Finder f) async {
        await tester.scrollUntilVisible(
          f,
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await scrollTap(find.text('Raket Falcon 80'));
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Toko Gesit Sport').last);
      await tester.pumpAndSettle();
      expect(find.text('Hubungi toko lewat WhatsApp'), findsOneWidget);
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      // Detail produk tadi tergulir ke bawah; tombol kembali ada di atas.
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 2000));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Bingung pilih raket atau sepatu?'),
        -150,
        scrollable: find.byType(Scrollable).first,
      );
      await tapVisible(tester, find.text('Bingung pilih raket atau sepatu?'));
      await tester.tap(find.text('Lihat saran'));
      await tester.pumpAndSettle();
      expect(find.text('Hasil saran'), findsOneWidget);
    });
  });
}
