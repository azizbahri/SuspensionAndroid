import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/processing/displacement_processor.dart';

void main() {
  group('DisplacementProcessor.adcToVoltage', () {
    test('0 counts → 0 V', () {
      final v = DisplacementProcessor.adcToVoltage([0]);
      expect(v[0], 0.0);
    });

    test('full-scale counts → vRef', () {
      final v = DisplacementProcessor.adcToVoltage([4095], adcBits: 12, vRef: 5.0);
      expect(v[0], closeTo(5.0, 0.002));
    });

    test('half-scale → vRef/2', () {
      final v = DisplacementProcessor.adcToVoltage([2048], adcBits: 12, vRef: 5.0);
      expect(v[0], closeTo(2.5, 0.003));
    });

    test('output length equals input length', () {
      final v = DisplacementProcessor.adcToVoltage([100, 200, 300]);
      expect(v.length, 3);
    });
  });

  group('DisplacementProcessor.frontStroke', () {
    test('s = (V - V0) × C', () {
      final v = Float64List.fromList([1.5]);
      final s = DisplacementProcessor.frontStroke(v, v0Front: 0.5, cFront: 42.0);
      expect(s[0], closeTo(42.0, 1e-6));
    });

    test('at V0 → stroke = 0', () {
      final v = Float64List.fromList([0.5]);
      final s = DisplacementProcessor.frontStroke(v, v0Front: 0.5, cFront: 42.0);
      expect(s[0], closeTo(0.0, 1e-6));
    });
  });

  group('DisplacementProcessor.frontTravel', () {
    test('travel = stroke × cos(θ)', () {
      final s = Float64List.fromList([100.0]);
      final w = DisplacementProcessor.frontTravel(s, forkAngleDeg: 0.0);
      expect(w[0], closeTo(100.0, 1e-6)); // cos(0) = 1
    });

    test('angle reduces travel', () {
      final s = Float64List.fromList([100.0]);
      final w = DisplacementProcessor.frontTravel(s, forkAngleDeg: 27.0);
      final expected = 100.0 * math.cos(math.pi / 180.0 * 27.0);
      expect(w[0], closeTo(expected, 1e-6));
    });
  });

  group('DisplacementProcessor.rearTravel (linkage)', () {
    test('W = a×s² + b×s + c', () {
      final s = Float64List.fromList([30.0]);
      // a=-0.015, b=4.2, c=0 → W = -0.015×900 + 4.2×30 + 0 = -13.5 + 126 = 112.5
      final w = DisplacementProcessor.rearTravel(s, a: -0.015, b: 4.2, c: 0.0);
      expect(w[0], closeTo(112.5, 0.01));
    });
  });

  group('DisplacementProcessor.travelPercent', () {
    test('50 mm of 210 mm → 23.8%', () {
      final w = Float64List.fromList([50.0]);
      final pct = DisplacementProcessor.travelPercent(w, wMaxMm: 210.0);
      expect(pct[0], closeTo(50.0 / 210.0 * 100.0, 0.001));
    });

    test('full travel → 100%', () {
      final w = Float64List.fromList([210.0]);
      final pct = DisplacementProcessor.travelPercent(w, wMaxMm: 210.0);
      expect(pct[0], closeTo(100.0, 0.001));
    });
  });
}
