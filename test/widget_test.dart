import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_50jt/db/db.dart';
import 'package:project_50jt/login.dart';
import 'package:project_50jt/theme.dart';

void main() {
  test('date keys are stable and display in Indonesian format', () {
    final date = DateTime(2026, 11, 2);

    expect(Db.dateKey(date), '2026-11-02');
    expect(Db.displayDate(Db.dateKey(date)), '2 Nov 2026');
  });

  testWidgets('login follows the Indonesian RAWAN design', (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: LoginScreen(onLogin: (_, _, _) {}),
      ),
    );

    expect(find.text('RAWAN'), findsOneWidget);
    expect(find.text('Masuk ke RAWAN'), findsOneWidget);
    expect(find.text('ID KARYAWAN ATAU EMAIL'), findsOneWidget);
    expect(find.text('Ingat saya'), findsOneWidget);
    expect(find.text('Butuh bantuan?'), findsOneWidget);

    await tester.ensureVisible(find.text('Masuk', skipOffstage: false));
    await tester.tap(find.text('Masuk', skipOffstage: false));
    await tester.pumpAndSettle();

    expect(find.text('NIP atau email wajib diisi.'), findsOneWidget);
  });
}
