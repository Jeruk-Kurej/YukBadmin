import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/main.dart';

/// Menjalankan alur pemain dari masuk sampai sheet hubungi pengurus pada
/// ukuran layar ponsel, untuk menangkap galat tata letak dan navigasi.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ProviderScope(child: YukBadminApp()));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.tap(find.text('Masuk dengan Google'));
    await tester.pumpAndSettle();
  }

  testWidgets('belum masuk diarahkan ke layar Masuk', (tester) async {
    await pumpApp(tester);
    expect(find.text('YukBadmin'), findsOneWidget);
    expect(find.text('Masuk dengan Google'), findsOneWidget);
  });

  testWidgets('masuk, isi preferensi, lalu sampai beranda', (tester) async {
    await pumpApp(tester);
    await signIn(tester);

    expect(find.text('Atur preferensi mainmu'), findsOneWidget);
    await tester.tap(find.text('Sab'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    expect(find.text('Siap main di mana?'), findsOneWidget);
    expect(find.text('PB terdekat'), findsOneWidget);
  });

  testWidgets('cari, filter, buka detail, simpan, dan hubungi pengurus', (
    tester,
  ) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cari PB'));
    await tester.pumpAndSettle();
    expect(find.text('PB terdaftar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'rungkut');
    await tester.pumpAndSettle();
    expect(find.text('PB Kok Kuning'), findsOneWidget);
    expect(find.text('PB Rajawali'), findsNothing);

    await tester.enterText(find.byType(TextField), 'tidak ada pb ini');
    await tester.pumpAndSettle();
    expect(find.text('Belum ada PB yang cocok'), findsOneWidget);
    await tester.tap(find.text('Hapus semua filter'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Filter'));
    await tester.pumpAndSettle();
    expect(find.text('Filter PB'), findsOneWidget);
    await tester.tap(find.text('S'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan 1 PB'));
    await tester.pumpAndSettle();
    expect(find.text('Filter (1)'), findsOneWidget);
    expect(find.text('PB Garuda Muda'), findsOneWidget);

    await tester.tap(find.text('PB Garuda Muda'));
    await tester.pumpAndSettle();
    expect(find.text('Kuota penuh'), findsOneWidget);

    await tester.tap(find.byTooltip('Simpan PB'));
    await tester.pump();
    expect(find.text('PB Garuda Muda disimpan'), findsOneWidget);

    await tester.tap(find.text('Tanya pengurus'));
    await tester.pumpAndSettle();
    expect(find.text('Buka WhatsApp'), findsOneWidget);
    expect(find.textContaining('Halo Pak Bambang, saya Bryan'), findsOneWidget);
  });

  testWidgets('layar kecil dan teks besar tidak meluber', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(tester, size: const Size(320, 640));
    await signIn(tester);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cari PB'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('PB Smash Surabaya'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('PB Smash Surabaya'));
    await tester.pumpAndSettle();
    expect(find.text('Tanya pengurus'), findsOneWidget);
  });
}
