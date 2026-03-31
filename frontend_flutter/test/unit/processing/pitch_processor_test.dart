import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/processing/pitch_processor.dart';

void main() {
  group('PitchProcessor.gyroToDegS', () {
    test('converts counts using sensitivity', () {
      final result = PitchProcessor.gyroToDegS([164], sensitivity: 16.4);
      expect(result[0], closeTo(10.0, 1e-6));
    });

    test('zero counts → zero deg/s', () {
      final result = PitchProcessor.gyroToDegS([0]);
      expect(result[0], 0.0);
    });
  });

  group('PitchProcessor.removeBias', () {
    test('subtracts mean of first stationarySamples', () {
      final signal = Float64List.fromList(
          List.generate(500, (i) => i < 50 ? 1.0 : 0.0));
      final (:corrected, :bias) =
          PitchProcessor.removeBias(signal, stationarySamples: 50);
      expect(bias, closeTo(1.0, 1e-6));
      // First samples corrected to near 0
      expect(corrected[0], closeTo(0.0, 1e-6));
      // Later samples corrected to -1
      expect(corrected[100], closeTo(-1.0, 1e-6));
    });

    test('already-zero signal stays zero', () {
      final signal = Float64List.fromList(List.filled(200, 0.0));
      final (:corrected, :bias) = PitchProcessor.removeBias(signal);
      expect(bias, 0.0);
      for (final v in corrected) {
        expect(v, 0.0);
      }
    });
  });

  group('PitchProcessor.accelPitchDeg', () {
    test('level attitude → pitch ≈ 0°', () {
      // ax=0, ay=0, az=1g → atan2(0, 1) = 0
      final ax = Float64List.fromList([0.0]);
      final ay = Float64List.fromList([0.0]);
      final az = Float64List.fromList([1.0]);
      final phi = PitchProcessor.accelPitchDeg(ax, ay, az);
      expect(phi[0], closeTo(0.0, 0.01));
    });

    test('90° nose-up → pitch ≈ +90°', () {
      // ax=-1g, ay=0, az=0 → atan2(1, 0) = 90°
      final ax = Float64List.fromList([-1.0]);
      final ay = Float64List.fromList([0.0]);
      final az = Float64List.fromList([0.0]);
      final phi = PitchProcessor.accelPitchDeg(ax, ay, az);
      expect(phi[0], closeTo(90.0, 0.1));
    });

    test('braking (ax < 0) → nose-down pitch < 0', () {
      // During braking ax is negative (deceleration)
      final ax = Float64List.fromList([0.5]); // positive longitudinal
      final ay = Float64List.fromList([0.0]);
      final az = Float64List.fromList([1.0]);
      final phi = PitchProcessor.accelPitchDeg(ax, ay, az);
      // atan2(-0.5, 1) < 0 → nose-down
      expect(phi[0], lessThan(0.0));
    });
  });

  group('PitchProcessor.complementaryFilterPitch', () {
    test('stationary (zero gyro, zero accel pitch) → zero pitch', () {
      final omega = Float64List.fromList(List.filled(200, 0.0));
      final phiAcc = Float64List.fromList(List.filled(200, 0.0));
      final phi = PitchProcessor.complementaryFilterPitch(
          omega, phiAcc, fsHz: 250.0);
      for (final v in phi) {
        expect(v, closeTo(0.0, 1e-6));
      }
    });

    test('output length equals input length', () {
      final n = 300;
      final omega = Float64List.fromList(List.filled(n, 0.0));
      final phiAcc = Float64List.fromList(List.filled(n, 0.0));
      final phi =
          PitchProcessor.complementaryFilterPitch(omega, phiAcc, fsHz: 250.0);
      expect(phi.length, n);
    });

    test('converges to accel pitch with zero gyro', () {
      // If gyro is zero and accel says 10°, filter should converge to 10°
      final omega = Float64List.fromList(List.filled(5000, 0.0));
      final phiAcc = Float64List.fromList(List.filled(5000, 10.0));
      final phi = PitchProcessor.complementaryFilterPitch(
          omega, phiAcc, fsHz: 250.0, alpha: 0.98);
      // After many samples, should be close to 10°
      expect(phi.last, closeTo(10.0, 0.5));
    });
  });
}
