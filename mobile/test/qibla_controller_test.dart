import 'package:flutter_test/flutter_test.dart';
import 'package:muslim_vegukin/features/qibla/qibla_controller.dart';
import 'package:muslim_vegukin/features/qibla/qibla_math.dart';

import 'support/fakes.dart';

/// The page's clock; [feed] moves it along with the readings.
var now = DateTime(2026, 10, 18, 12);

/// Ansan (the fakes' place): declination −8.94°, Qibla 285.75°.
Future<(QiblaController, FakeQiblaDevice)> started(WidgetTester tester, {bool compass = true}) async {
  final app = TestApp();
  await app.prayer.start();
  final device = FakeQiblaDevice(compass: compass);
  final c = QiblaController(device: device, prayer: app.prayer, clock: () => now);
  await c.start();
  return (c, device);
}

Future<void> feed(WidgetTester tester, FakeQiblaDevice d, int count,
    {double top = 0, double tilt = 5, int status = 3, double accuracy = 5, double field = 51.3, double camera = 0}) async {
  for (var i = 0; i < count; i++) {
    now = now.add(const Duration(milliseconds: 33));
    d.send(top: top, tilt: tilt, status: status, accuracy: accuracy, field: field, camera: camera);
    await tester.pump(const Duration(milliseconds: 33));
  }
}

void main() {
  testWidgets('a steady, calibrated compass goes straight to the compass', (tester) async {
    final (c, d) = await started(tester);
    expect(c.phase, QiblaPhase.loading);
    expect(d.screenOn, isTrue);
    await feed(tester, d, 10, top: 300);
    expect(c.phase, QiblaPhase.compass);
    // True heading = magnetic + declination (−8.94° here).
    expect(c.heading, closeTo(291.06, 0.05));
    expect(c.qibla!.bearing, closeTo(285.75, 0.01));
    expect(c.difference, closeTo(-5.3, 0.1));
    expect(c.facing, Facing.close);
    expect(c.quality, 4);
    c.dispose();
  });

  testWidgets('facing the Qibla within 5° reads as aligned', (tester) async {
    final (c, d) = await started(tester);
    await feed(tester, d, 12, top: 285.75 + 8.94 + 2);
    expect(c.facing, Facing.aligned);
    c.dispose();
  });

  testWidgets('an uncalibrated compass asks for calibration, then both steps finish it', (tester) async {
    final (c, d) = await started(tester);
    await feed(tester, d, 10, top: 100, status: 1, accuracy: 40);
    await tester.pump(const Duration(seconds: 2));
    expect(c.phase, QiblaPhase.calibrating);
    expect(c.step, CalibrationStep.move);

    // Eight turns of more than 30°, over at least five seconds.
    for (var i = 1; i <= 8; i++) {
      await feed(tester, d, 20, top: 100 + i * 45.0, status: 2, accuracy: 10);
    }
    expect(c.movements, 8);
    expect(c.step, CalibrationStep.hold);

    // Then flat and still.
    await feed(tester, d, 50, top: 200, status: 3, accuracy: 6);
    expect(c.holdProgress, 1);
    await tester.pump(const Duration(milliseconds: 600));
    expect(c.phase, QiblaPhase.compass);
    c.dispose();
  });

  testWidgets('still but uncalibrated: back to turning, with some turns kept', (tester) async {
    final (c, d) = await started(tester);
    c.recalibrate();
    for (var i = 1; i <= 8; i++) {
      await feed(tester, d, 20, top: i * 45.0, status: 2, accuracy: 10);
    }
    expect(c.step, CalibrationStep.hold);
    await feed(tester, d, 120, top: 10, status: 1, accuracy: 40);
    expect(c.step, CalibrationStep.move);
    expect(c.movements, QiblaController.movementsNeeded - 4);
    c.dispose();
  });

  testWidgets('a field far from the model\'s means metal nearby', (tester) async {
    final (c, d) = await started(tester);
    expect(c.expectedField, closeTo(51.34, 0.1));
    await feed(tester, d, 10, top: 300, field: 90);
    expect(c.issue, SignalIssue.interference);
    expect(c.quality, 1);
    c.dispose();
  });

  testWidgets('standing up, the heading is where the camera looks', (tester) async {
    final (c, d) = await started(tester);
    await feed(tester, d, 12, top: 10, camera: 120, tilt: 85);
    expect(c.heading, closeTo(normalizeDegrees(120 - 8.94), 0.1));
    c.dispose();
  });

  testWidgets('without a place or a compass the page says so', (tester) async {
    final app = TestApp(); // never located
    final c = QiblaController(device: FakeQiblaDevice(), prayer: app.prayer);
    await c.start();
    expect(c.phase, QiblaPhase.noLocation);
    final (c2, _) = await started(tester, compass: false);
    expect(c2.phase, QiblaPhase.noCompass);
    c.dispose();
    c2.dispose();
  });
}
