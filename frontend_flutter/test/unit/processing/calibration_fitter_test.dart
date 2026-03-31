import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/processing/calibration_fitter.dart';

void main() {
  group('CalibrationFitter.fitFrontLinear', () {
    test('perfect linear data gives exact C_cal and V0', () {
      // Calibration: s = 42 × (V - 0.5) → C_cal=42, V0=0.5
      final strokes = [0.0, 42.0, 84.0, 126.0, 168.0, 210.0];
      final voltages = [0.5, 1.5, 2.5, 3.5, 4.5, 5.5];
      final result = CalibrationFitter.fitFrontLinear(
          strokesMm: strokes, voltagesV: voltages);
      expect(result.cCal, closeTo(42.0, 0.001));
      expect(result.v0, closeTo(0.5, 0.001));
      expect(result.rmseMm, closeTo(0.0, 1e-6));
    });

    test('RMSE is zero for perfect linear fit', () {
      final strokes = [0.0, 100.0, 200.0];
      final voltages = [0.5, 1.5, 2.5];
      final result = CalibrationFitter.fitFrontLinear(
          strokesMm: strokes, voltagesV: voltages);
      expect(result.rmseMm, closeTo(0.0, 1e-10));
    });

    test('throws for fewer than 2 points', () {
      expect(
          () => CalibrationFitter.fitFrontLinear(
              strokesMm: [0.0], voltagesV: [0.5]),
          throwsArgumentError);
    });

    test('result object has correct string representation', () {
      final r = const FrontCalibrationResult(cCal: 42.0, v0: 0.5, rmseMm: 0.001);
      expect(r.toString(), contains('42.00'));
      expect(r.toString(), contains('0.500'));
    });
  });

  group('CalibrationFitter.fitRearLinkage', () {
    test('perfect quadratic data gives exact a, b, c', () {
      // W = -0.015s² + 4.2s + 0
      final strokes = [0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0];
      final travels =
          strokes.map((s) => -0.015 * s * s + 4.2 * s).toList();
      final result = CalibrationFitter.fitRearLinkage(
          shockStrokesMm: strokes, wheelTravelsMm: travels);
      expect(result.a, closeTo(-0.015, 1e-8));
      expect(result.b, closeTo(4.2, 1e-8));
      expect(result.c, closeTo(0.0, 1e-8));
      expect(result.rmseMm, closeTo(0.0, 1e-6));
    });

    test('throws for fewer than 3 points', () {
      expect(
          () => CalibrationFitter.fitRearLinkage(
              shockStrokesMm: [0.0, 10.0], wheelTravelsMm: [0.0, 40.0]),
          throwsArgumentError);
    });
  });
}
