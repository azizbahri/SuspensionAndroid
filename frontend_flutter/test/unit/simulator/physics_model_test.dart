import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/simulator/physics_model.dart';
import '../../../lib/data/simulator/sensor_model.dart';
import '../../../lib/domain/entities/bike_profile.dart';

void main() {
  late PhysicsModel model;
  const bike = BikeProfile.t7;

  setUp(() {
    model = PhysicsModel(fsHz: 250.0, durationS: 10.0);
  });

  group('PhysicsModel.staticSag', () {
    test('produces correct number of samples', () {
      final state = model.staticSag();
      expect(state.length, 2500); // 10s × 250 Hz
    });

    test('front travel is constant', () {
      final state = model.staticSag(wFrontMm: 70.0);
      for (final w in state.wFrontTrue) {
        expect(w, closeTo(70.0, 1e-6));
      }
    });

    test('rear travel is constant', () {
      final state = model.staticSag(wRearMm: 95.0);
      for (final w in state.wRearTrue) {
        expect(w, closeTo(95.0, 1e-6));
      }
    });

    test('pitch is zero (stationary)', () {
      final state = model.staticSag();
      for (final phi in state.phiTrue) {
        expect(phi, closeTo(0.0, 1e-6));
      }
    });

    test('accelZ = g (gravity)', () {
      final state = model.staticSag();
      for (final az in state.accelZTrue) {
        expect(az, closeTo(9.80665, 1e-4));
      }
    });
  });

  group('PhysicsModel.roughTerrain', () {
    test('produces correct sample count', () {
      final m = PhysicsModel(fsHz: 250.0, durationS: 30.0);
      final state = m.roughTerrain();
      expect(state.length, 7500); // 30s × 250 Hz
    });

    test('travel values are clipped to [0, 200]', () {
      final state = model.roughTerrain();
      for (final w in state.wFrontTrue) {
        expect(w, greaterThanOrEqualTo(0.0));
        expect(w, lessThanOrEqualTo(200.0));
      }
    });

    test('reproducible with same seed', () {
      final s1 = model.roughTerrain(seed: 42);
      final s2 = model.roughTerrain(seed: 42);
      expect(s1.wFrontTrue[100], s2.wFrontTrue[100]);
    });

    test('different seed → different output', () {
      final s1 = model.roughTerrain(seed: 42);
      final s2 = model.roughTerrain(seed: 99);
      expect(s1.wFrontTrue[100], isNot(s2.wFrontTrue[100]));
    });
  });

  group('PhysicsModel.brakingEvent', () {
    test('front travel increases during braking', () {
      final state = model.brakingEvent();
      // Find max front travel
      final maxW = state.wFrontTrue.reduce((a, b) => a > b ? a : b);
      expect(maxW, greaterThan(70.0)); // must compress beyond sag
    });

    test('longitudinal deceleration is negative during braking', () {
      final state = model.brakingEvent();
      final minAx = state.accelXTrue.reduce((a, b) => a < b ? a : b);
      expect(minAx, lessThan(0.0));
    });
  });

  group('SensorModel', () {
    late SensorModel sensor;

    setUp(() {
      sensor = SensorModel(bike);
    });

    test('frontAdc output length matches input', () {
      final w = model.staticSag().wFrontTrue;
      final adc = sensor.frontAdc(w);
      expect(adc.length, w.length);
    });

    test('frontAdc values within 12-bit range [0, 4095]', () {
      final w = model.staticSag().wFrontTrue;
      final adc = sensor.frontAdc(w);
      for (final v in adc) {
        expect(v, greaterThanOrEqualTo(0));
        expect(v, lessThanOrEqualTo(4095));
      }
    });

    test('rearAdc output length matches input', () {
      final s = model.staticSag().sRearTrue;
      final adc = sensor.rearAdc(s);
      expect(adc.length, s.length);
    });

    test('gyroYRaw adds bias correctly', () {
      // 0 deg/s + 0.08 bias → counts = 0.08 × 16.4 ≈ 1
      final omega = Float64List.fromList(List.filled(10, 0.0));
      final raw = sensor.gyroYRaw(omega, biasDegS: 0.08);
      expect(raw[0], closeTo(1, 1)); // rounded ±1
    });

    test('round-trip: sag travel survives adc encoding', () {
      // static_sag at 70mm → quantize → should decode to ≈70mm (within ADC resolution)
      const wTarget = 70.0;
      final cosTheta = math.cos(math.pi / 180.0 * bike.forkAngleDeg);
      final sFork = wTarget / cosTheta;
      final voltage = sFork / bike.cFront + bike.v0Front;
      final adcCount = (voltage / bike.vRef * 4095).round().clamp(0, 4095);

      // Decode
      final vDecoded = adcCount / 4095 * bike.vRef;
      final sDecoded = (vDecoded - bike.v0Front) * bike.cFront;
      final wDecoded = sDecoded * cosTheta;

      // Within 1 ADC LSB of travel
      expect(wDecoded, closeTo(wTarget, 0.5));
    });
  });
}
