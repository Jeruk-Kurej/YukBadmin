import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

import 'test_helpers.dart';

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
    await signInWithEmail(tester);
  }

  testWidgets('belum masuk diarahkan ke layar Masuk', (tester) async {
    await pumpApp(tester);
    expect(find.text('YukBadmin'), findsOneWidget);
    expect(find.text('Lanjut dengan Google'), findsOneWidget);
  });

  testWidgets(
    'daftar dengan email menolak isian salah, lalu akun belum terverifikasi',
    (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Masuk dengan email'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buat akun').last);
      await tester.pumpAndSettle();
      expect(find.text('Isi namamu, minimal 2 huruf.'), findsOneWidget);
      expect(
        find.text('Isi email yang benar, misalnya nama@email.com.'),
        findsOneWidget,
      );
      expect(find.text('Kata sandi minimal 8 karakter.'), findsOneWidget);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Sinta Dewi');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'sinta@contoh.id');
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(2), 'rahasia123');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Buat akun').last);
      await tester.pumpAndSettle();

      expect(find.text('Atur preferensi mainmu'), findsOneWidget);
      final c = ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
      final user = c.read(sessionProvider)!;
      expect(user.name, 'Sinta Dewi');
      expect(user.emailVerified, isFalse);
    },
  );

  testWidgets('masuk, isi preferensi, lalu sampai beranda', (tester) async {
    await pumpApp(tester);
    await signIn(tester);

    expect(find.text('Atur preferensi mainmu'), findsOneWidget);
    await tester.ensureVisible(find.text('Sab'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sab'));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();

    final c = ProviderScope.containerOf(
      tester.element(find.byType(YukBadminApp)),
    );
    expect(c.read(preferencesProvider).weekdays, contains(DateTime.saturday));

    expect(find.text('Halo, Bryan'), findsOneWidget);
    expect(find.text('Jadwalmu'), findsOneWidget);
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
    expect(find.textContaining('PB terdaftar'), findsOneWidget);

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
    // Kotak level juga ada di halaman Cari; yang di sheet ada di atas.
    await tester.tap(find.text('S').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tampilkan 1 PB'));
    await tester.pumpAndSettle();
    expect(find.text('Filter · 1'), findsOneWidget);
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

  testWidgets('PB yang sudah dihubungi muncul di PB tersimpan', (tester) async {
    await pumpApp(tester);
    await signIn(tester);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(
      tester.element(find.byType(YukBadminApp)),
    );
    c.read(routerProvider).push('/tersimpan');
    await tester.pumpAndSettle();
    expect(find.text('Sudah kamu hubungi'), findsNothing);
    expect(find.text('Belum ada PB tersimpan'), findsOneWidget);

    c
        .read(contactedProvider.notifier)
        .mark('pb-smash-surabaya', DateTime(2026, 11, 16, 9));
    await tester.pumpAndSettle();
    expect(find.text('Sudah kamu hubungi'), findsOneWidget);
    expect(find.text('Dihubungi lewat WhatsApp · Sen, 16 Nov'), findsOneWidget);
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
    await tester.ensureVisible(find.text('PB Smash Surabaya'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PB Smash Surabaya'));
    await tester.pumpAndSettle();
    expect(find.text('Tanya pengurus'), findsOneWidget);
  });
}
