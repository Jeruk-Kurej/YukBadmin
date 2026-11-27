import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/app/router.dart';
import 'package:yukbadmin/features/manage/state/manage_providers.dart';
import 'package:yukbadmin/features/pb/data/pb_models.dart';
import 'package:yukbadmin/features/pb/data/pb_repository.dart';
import 'package:yukbadmin/features/pb/state/providers.dart';
import 'package:yukbadmin/main.dart';

void main() {
  testWidgets('dialog bisa ditutup saat keyboard ikut turun', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(const ProviderScope(child: YukBadminApp()));
    final c = ProviderScope.containerOf(t.element(find.byType(YukBadminApp)));
    c.read(sessionProvider.notifier).signInDemo();
    final n = c.read(manageProvider.notifier);
    n.registerPb((await const SeedPbRepository().fetchAll()).first);
    final a = n.addMember(name: 'Andi', type: MemberType.tetap).id;
    final e = c.read(manageProvider).events.first.id;
    n.saveAttendance(e, {a});
    await t.pumpAndSettle();
    c.read(routerProvider).push('/sesi/$e/iuran');
    await t.pumpAndSettle();

    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.tap(find.byIcon(Icons.edit_outlined));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '120000');
    await t.tap(find.text('Simpan'));
    await t.pump(const Duration(milliseconds: 20));
    t.view.viewInsets = FakeViewPadding.zero;
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);

    c.read(routerProvider).push('/impor');
    await t.pumpAndSettle();
    await t.tap(find.text('Isi dengan contoh'));
    await t.tap(find.text('Baca catatan'));
    await t.pumpAndSettle();
    t.view.viewInsets = const FakeViewPadding(bottom: 300);
    await t.tap(find.byTooltip('Perbaiki Eko S.'));
    await t.pumpAndSettle();
    await t.tap(find.text('Pakai nama ini'));
    await t.pump(const Duration(milliseconds: 20));
    t.view.viewInsets = FakeViewPadding.zero;
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
