import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yukbadmin/features/auth/data/local_accounts.dart';

/// Masuk lewat layar "Masuk dengan email", bawaannya ke akun contoh.
Future<void> signInWithEmail(
  WidgetTester tester, {
  String email = demoEmail,
  String password = demoPassword,
}) async {
  await tester.tap(find.text('Masuk dengan email'));
  await tester.pumpAndSettle();
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), email);
  await tester.pumpAndSettle();
  await tester.enterText(fields.at(1), password);
  await tester.pumpAndSettle();
  final submit = find.widgetWithText(FilledButton, 'Masuk');
  await tester.ensureVisible(submit);
  await tester.pumpAndSettle();
  await tester.tap(submit);
  await tester.pumpAndSettle();
}
