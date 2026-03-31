import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/processing/velocity_processor.dart';

void main() {
  group('VelocityProcessor.filterDisplacement', () {
    test('returns same-length output', () {
      final signal = Float64List.fromList(
          List.generate(200, (i) => i.toDouble()));
      final filtered = VelocityProcessor.filterDisplacement(signal, fsHz: 250.0);
      expect(filtered.length, 200);
    });

    test('short signal returned unchanged', () {
      final signal = Float64List.fromList([1.0, 2.0, 3.0]);
      final filtered = VelocityProcessor.filterDisplacement(signal, fsHz: 250.0);
      expect(filtered[0], 1.0);
      expect(filtered[2], 3.0);
    });
  });

  group('VelocityProcessor.wheelVelocity', () {
    test('zero velocity for constant signal', () {
      final signal =
          Float64List.fromList(List.filled(100, 70.0)); // constant = no motion
      final v = VelocityProcessor.wheelVelocity(signal, fsHz: 250.0);
      // All samples except first should be near zero
      for (int i = 1; i < v.length; i++) {
        expect(v[i], closeTo(0.0, 1e-6));
      }
    });

    test('linear increase → constant negative velocity', () {
      // W increases by 1 mm every sample → velocity = -1 × fs
      final fs = 250.0;
      final signal = Float64List.fromList(
          List.generate(200, (i) => i.toDouble()));
      final v = VelocityProcessor.wheelVelocity(signal, fsHz: fs);
      // After filter transient (skip first ~20 samples)
      for (int i = 20; i < v.length; i++) {
        expect(v[i], closeTo(-fs, 0.1));
      }
    });

    test('compression (increasing travel) gives negative velocity', () {
      // Travel goes from 0 to 100 mm → compression → sign should be negative
      final fs = 250.0;
      final signal = Float64List.fromList(
          List.generate(200, (i) => i / 2.0)); // increasing
      final filtered = VelocityProcessor.filterDisplacement(signal, fsHz: fs);
      final v = VelocityProcessor.wheelVelocity(filtered, fsHz: fs);
      // Mid-session velocity should be negative (compression)
      expect(v[100], lessThan(0));
    });
  });

  group('VelocityProcessor.shaftVelocityFront', () {
    test('v_shaft = v_wheel / cos(theta) at 0 deg', () {
      final vWheel = Float64List.fromList([-100.0]);
      final vShaft = VelocityProcessor.shaftVelocityFront(
          vWheel, forkAngleDeg: 0.0);
      expect(vShaft[0], closeTo(-100.0, 1e-6));
    });

    test('27 deg angle increases shaft velocity magnitude', () {
      final vWheel = Float64List.fromList([-100.0]);
      final vShaft = VelocityProcessor.shaftVelocityFront(
          vWheel, forkAngleDeg: 27.0);
      // cos(27°) ≈ 0.891, so v_shaft = -100/0.891 ≈ -112.2
      expect(vShaft[0].abs(), greaterThan(100.0));
    });
  });
}
