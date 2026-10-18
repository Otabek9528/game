import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/qibla/camera_view.dart';
import 'package:muslim_vegukin/features/qibla/qibla_screen.dart';
import 'package:muslim_vegukin/features/qibla/qibla_sensors.dart';

import 'support/fakes.dart';

/// Opens the Qibla page from the home grid. Ansan: the Qibla is at 285.75°,
/// the declination −8.94°.
Future<TestApp> openQibla(WidgetTester tester) async {
  final app = TestApp(language: 'en');
  await app.launch(tester);
  await tester.scrollUntilVisible(find.text('Qibla'), 200);
  await tester.tap(find.text('Qibla'));
  // The loading spinner never settles: pump through the page transition.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(find.byType(QiblaScreen), findsOneWidget);
  return app;
}

Future<void> face(WidgetTester tester, TestApp app, double magnetic,
    {int count = 12, int status = 3, double accuracy = 5, double field = 51.3}) async {
  for (var i = 0; i < count; i++) {
    app.qibla.send(top: magnetic, status: status, accuracy: accuracy, field: field);
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void main() {
  testWidgets('the compass says which way to turn, and when the Qibla is reached', (tester) async {
    final app = await openQibla(tester);
    expect(find.text('Preparing compass...'), findsOneWidget);
    expect(app.qibla.screenOn, isTrue);

    await face(tester, app, 300); // true 291°: 5° past the Qibla
    expect(find.text('Turn slightly left'), findsOneWidget);
    expect(find.text('285.8°'), findsOneWidget);
    expect(find.text('Excellent'), findsOneWidget);
    expect(find.textContaining('Magnetic declination −8.9°'), findsOneWidget);

    // A big turn: the smoothing needs about a second of readings.
    await face(tester, app, 285.75 + 8.94 - 60, count: 30);
    expect(find.text('Turn right 60°'), findsOneWidget);

    await face(tester, app, 285.75 + 8.94, count: 30);
    expect(find.text('You are facing the Qibla!'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(app.qibla.screenOn, isFalse);
  });

  testWidgets('an uncalibrated compass shows the two calibration steps', (tester) async {
    final app = await openQibla(tester);
    await face(tester, app, 100, status: 1, accuracy: 40);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Calibrate the compass'), findsOneWidget);
    expect(find.text('0/8 movements'), findsOneWidget);
  });

  testWidgets('metal nearby is called out', (tester) async {
    final app = await openQibla(tester);
    await face(tester, app, 300, field: 95);
    await tester.pump(const Duration(seconds: 2));
    // Not steady enough to trust: it goes to calibration, and says why on
    // the compass once calibrated.
    expect(find.text('Calibrate the compass'), findsOneWidget);
  });

  testWidgets('the camera view, without camera permission, points to Settings', (tester) async {
    final app = await openQibla(tester);
    app.qibla.cameraProblem = CameraProblem.permission;
    await face(tester, app, 300);
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    expect(find.byType(CameraQiblaView), findsOneWidget);
    expect(find.text('Camera access is off for this app'), findsOneWidget);
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('the camera view shows the camera and the turn instruction', (tester) async {
    final app = await openQibla(tester);
    await face(tester, app, 300);
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 10; i++) {
      app.qibla.send(top: 0, camera: 285.75 + 8.94 + 20, tilt: 88);
      await tester.pump(const Duration(milliseconds: 33));
    }
    expect(find.byType(Texture), findsOneWidget);
    expect(find.text('Turn slightly left'), findsNothing);
    expect(find.text('Turn left'), findsOneWidget);
  });

  testWidgets('seven taps on the title open the diagnostics', (tester) async {
    final app = await openQibla(tester);
    await face(tester, app, 300);
    for (var i = 0; i < 7; i++) {
      await tester.tap(find.text('Qibla direction'));
    }
    await tester.pumpAndSettle();
    expect(find.text('REC 3s'), findsOneWidget);
  });
}
