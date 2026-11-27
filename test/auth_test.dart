import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/core/data/local_store.dart';
import 'package:yukbadmin/features/auth/data/local_accounts.dart';
import 'package:yukbadmin/features/auth/state/auth_providers.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

import 'test_helpers.dart';

void main() {
  group('akun lokal', () {
    late MemoryLocalStore store;
    late ProviderContainer c;

    ProviderContainer open() {
      final container = ProviderContainer(
        overrides: [localStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      return container;
    }

    setUp(() {
      store = MemoryLocalStore();
      c = open();
    });

    AccountsNotifier accounts() => c.read(accountsProvider.notifier);

    test('daftar membuka sesi dengan email belum terverifikasi', () {
      final error = accounts().register(
        name: 'Sinta Dewi',
        email: 'Sinta@Contoh.id ',
        password: 'rahasia123',
      );
      expect(error, isNull);
      final user = c.read(sessionProvider)!;
      expect(user.email, 'sinta@contoh.id');
      expect(user.emailVerified, isFalse);
    });

    test('email yang sudah terdaftar tidak bisa didaftarkan lagi', () {
      accounts().register(name: 'A', email: 'a@b.id', password: 'rahasia123');
      expect(
        accounts().register(name: 'B', email: 'A@b.id', password: 'lainlain1'),
        AuthError.emailTaken,
      );
      expect(
        accounts().register(name: 'C', email: demoEmail, password: 'x' * 8),
        AuthError.emailTaken,
      );
    });

    test('masuk ditolak kalau akun belum ada atau kata sandi salah', () {
      expect(
        accounts().signIn(email: 'baru@contoh.id', password: 'rahasia123'),
        AuthError.notRegistered,
      );
      expect(c.read(sessionProvider), isNull);
      expect(
        accounts().signIn(email: demoEmail, password: 'salahsalah'),
        AuthError.wrongPassword,
      );
      expect(c.read(sessionProvider), isNull);
      expect(
        accounts().signIn(email: demoEmail, password: demoPassword),
        isNull,
      );
      expect(c.read(sessionProvider)!.name, demoName);
    });

    test(
      'akun tetap ada setelah app dibuka ulang, kata sandi tidak disimpan',
      () {
        accounts().register(
          name: 'Sinta',
          email: 'sinta@contoh.id',
          password: 'rahasia123',
        );
        expect(store.read(CacheKeys.accounts), isNot(contains('rahasia123')));

        final reopened = open();
        reopened.read(sessionProvider.notifier).signOut();
        expect(
          reopened
              .read(accountsProvider.notifier)
              .signIn(email: 'sinta@contoh.id', password: 'rahasia123'),
          isNull,
        );
      },
    );

    test('preferensi ditandai selesai per akun', () {
      accounts().register(name: 'A', email: 'a@b.id', password: 'rahasia123');
      expect(accounts().preferencesDone('a@b.id'), isFalse);
      accounts().markPreferencesDone('a@b.id');
      expect(accounts().preferencesDone('a@b.id'), isTrue);
      expect(accounts().preferencesDone(demoEmail), isFalse);
    });
  });

  group('layar masuk', () {
    Future<ProviderContainer> pumpApp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ProviderScope(child: YukBadminApp()));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(
        tester.element(find.byType(YukBadminApp)),
      );
    }

    testWidgets('Google belum bisa dipakai dan tidak masuk ke akun contoh', (
      tester,
    ) async {
      final c = await pumpApp(tester);
      await tester.tap(find.text('Lanjut dengan Google'));
      await tester.pump();
      expect(find.textContaining('tersambung ke server'), findsOneWidget);
      expect(c.read(sessionProvider), isNull);
    });

    testWidgets('email yang belum terdaftar ditolak dengan pesan', (
      tester,
    ) async {
      final c = await pumpApp(tester);
      await signInWithEmail(
        tester,
        email: 'belum@contoh.id',
        password: 'rahasia123',
      );
      expect(find.text(AuthError.notRegistered.message), findsOneWidget);
      expect(c.read(sessionProvider), isNull);
    });

    testWidgets('kata sandi salah ditolak dengan pesan', (tester) async {
      final c = await pumpApp(tester);
      await signInWithEmail(tester, password: 'salahsalah');
      expect(find.text(AuthError.wrongPassword.message), findsOneWidget);
      expect(c.read(sessionProvider), isNull);
    });

    testWidgets('preferensi hanya muncul saat pertama kali masuk', (
      tester,
    ) async {
      final c = await pumpApp(tester);
      await signInWithEmail(tester);
      expect(find.text('Atur preferensi mainmu'), findsOneWidget);
      await tester.tap(find.text('Lewati'));
      await tester.pumpAndSettle();
      expect(find.text('Halo, Bryan'), findsOneWidget);

      c.read(sessionProvider.notifier).signOut();
      await tester.pumpAndSettle();
      expect(find.text('Masuk dengan email'), findsOneWidget);

      await signInWithEmail(tester);
      expect(find.text('Atur preferensi mainmu'), findsNothing);
      expect(find.text('Halo, Bryan'), findsOneWidget);
    });
  });
}
