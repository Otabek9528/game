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

  testWidgets('an uncalibrated compass says so; calibration runs when asked, both steps', (tester) async {
    final (c, d) = await started(tester);
    await feed(tester, d, 10, top: 100, status: 1, accuracy: 40);
    await tester.pump(const Duration(seconds: 2));
    // Never sent there by itself.
    expect(c.phase, QiblaPhase.compass);
    expect(c.issue, SignalIssue.needsCalibration);
    expect(c.quality, 1);

    c.recalibrate();
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

  testWidgets('skipping calibration goes back to the compass', (tester) async {
    final (c, d) = await started(tester);
    await feed(tester, d, 5, top: 100);
    c.recalibrate();
    await feed(tester, d, 20, top: 150, status: 2, accuracy: 10);
    expect(c.phase, QiblaPhase.calibrating);
    c.skipCalibration();
    expect(c.phase, QiblaPhase.compass);
    expect(c.calibrationDone, isFalse);
    c.dispose();
  });

  testWidgets('aligned holds until the phone is clearly past the edge', (tester) async {
    final (c, d) = await started(tester);
    // [off] degrees short of the Qibla: magnetic = Qibla − off − declination.
    Future<Facing> at(double off) async {
      await feed(tester, d, 40, top: 285.75 - off + 8.94);
      return c.facing;
    }

    expect(await at(4), Facing.aligned);
    expect(await at(7), Facing.aligned, reason: 'inside the 3° release band');
    expect(await at(9), Facing.close);
    expect(await at(6), Facing.close, reason: 'back in only at 5°');
    expect(await at(4), Facing.aligned);
    expect(await at(17), Facing.close);
    expect(await at(19), Facing.turn);
    c.dispose();
  });

  testWidgets('tapping the real sun corrects the compass, and undo restores it', (tester) async {
    now = DateTime.utc(2026, 10, 18, 3); // noon in Ansan: the sun is up
    final (c, d) = await started(tester);
    await feed(tester, d, 20, top: 200, tilt: 85, camera: 200);
    final before = c.heading;
    final sun = c.sun!;
    expect(sun.up, isTrue);

    // The page put the real sun at a bearing 7° short of its true one:
    // everything it shows is 7° low.
    c.correctBySun(sun.azimuth - 7);
    expect(c.correction, closeTo(7, 1e-9));
    expect(c.heading, closeTo(normalizeDegrees(before + 7), 1e-6));
    // It holds for the readings that follow.
    await feed(tester, d, 20, top: 200, tilt: 85, camera: 200);
    expect(c.heading, closeTo(normalizeDegrees(before + 7), 0.01));

    c.clearCorrection();
    expect(c.correction, 0);
    await feed(tester, d, 20, top: 200, tilt: 85, camera: 200);
    expect(c.heading, closeTo(before, 0.01));
    c.dispose();
  });

  testWidgets('no sun, no correction', (tester) async {
    now = DateTime.utc(2026, 10, 18, 14); // 23:00 in Ansan
    final (c, d) = await started(tester);
    await feed(tester, d, 10, top: 200);
    c.correctBySun(100);
    expect(c.correction, 0);
    c.dispose();
  });

  testWidgets('a field far from the model\'s means metal nearby', (tester) async {
    final (c, d) = await started(tester);
    expect(c.expectedField, closeTo(51.34, 0.1));
    await feed(tester, d, 10, top: 300, field: 90);
    expect(c.issue, SignalIssue.interference);
    // A warning, not a failing grade: the heading may still be right.
    expect(c.quality, 2);
    c.dispose();
  });

  testWidgets('the signal doesn\'t flicker when readings waver at an edge', (tester) async {
    final (c, d) = await started(tester);
    // No accuracy from the phone (as on a Galaxy S22): the rating comes from
    // the heading's waver; the field wanders around the warning threshold.
    final changes = <int>[];
    var last = -1;
    for (var i = 0; i < 150; i++) {
      final noise = const [0.0, 2.6, -1.8, 3.1, -2.9, 0.4][i % 6];
      now = now.add(const Duration(milliseconds: 33));
      d.send(top: 300 + noise, accuracy: -1, status: 3, field: i.isEven ? 70 : 72);
      await tester.pump(const Duration(milliseconds: 33));
      if (c.quality != last) {
        changes.add(c.quality);
        last = c.quality;
      }
    }
    expect(changes.length, lessThanOrEqualTo(3));
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
