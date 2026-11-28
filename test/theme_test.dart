import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/theme.dart';
import 'package:yukbadmin/app/theme_mode.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/main.dart';

import 'test_helpers.dart';

void main() {
  // Palet aktif disimpan global; kembalikan ke terang setelah tiap tes.
  tearDown(() => YbColors.use(Brightness.light));

  test('mode tampilan menentukan kecerahan', () {
    expect(
      resolveBrightness(ThemeMode.system, Brightness.dark),
      Brightness.dark,
    );
    expect(
      resolveBrightness(ThemeMode.light, Brightness.dark),
      Brightness.light,
    );
    expect(
      resolveBrightness(ThemeMode.dark, Brightness.light),
      Brightness.dark,
    );
  });

  Future<ProviderContainer> openAccount(
    WidgetTester tester, {
    LocalStore? store,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          if (store != null) localStoreProvider.overrideWithValue(store),
        ],
        child: const YukBadminApp(),
      ),
    );
    await tester.pumpAndSettle();
    await signInWithEmail(tester);
    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akun'));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(YukBadminApp)));
  }

  Color scaffoldColor(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(Scaffold).first))
          .scaffoldBackgroundColor;

  testWidgets('pilih Gelap di Akun, lalu kembali ke Terang', (tester) async {
    final store = MemoryLocalStore();
    await openAccount(tester, store: store);
    expect(scaffoldColor(tester), YbPalette.light.bg);

    await tester.ensureVisible(find.text('Gelap'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gelap'));
    await tester.pumpAndSettle();
    expect(YbColors.isDark, isTrue);
    expect(scaffoldColor(tester), YbPalette.dark.bg);
    expect(store.read(CacheKeys.themeMode), '"dark"');

    await tester.ensureVisible(find.text('Terang'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();
    expect(YbColors.isDark, isFalse);
    expect(scaffoldColor(tester), YbPalette.light.bg);
  });

  testWidgets('isian tidak hilang saat tema berganti', (tester) async {
    final c = await openAccount(tester);
    await tester.tap(cariPbTab);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'rungkut');
    await tester.pumpAndSettle();

    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    expect(YbColors.isDark, isTrue);
    expect(find.text('rungkut'), findsOneWidget);
    expect(find.text('PB Kok Kuning'), findsOneWidget);
  });

  testWidgets('ikut sistem: berubah saat ponsel masuk mode gelap', (
    tester,
  ) async {
    await openAccount(tester);
    expect(YbColors.isDark, isFalse);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpAndSettle();
    expect(YbColors.isDark, isTrue);
    expect(scaffoldColor(tester), YbPalette.dark.bg);
  });

  testWidgets('mode gelap di layar kecil dan teks besar tidak meluber', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final c = await openAccount(tester, size: const Size(320, 640));
    c.read(themeModeProvider.notifier).set(ThemeMode.dark);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(cariPbTab);
    await tester.pumpAndSettle();
    expect(YbColors.isDark, isTrue);
  });
}
