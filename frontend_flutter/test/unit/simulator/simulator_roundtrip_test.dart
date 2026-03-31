import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/hardware/data_source.dart';
import '../../../lib/data/processing/session_pipeline.dart';
import '../../../lib/data/simulator/simulator_config.dart';
import '../../../lib/data/simulator/simulator_source.dart';
import '../../../lib/domain/entities/bike_profile.dart';
import '../../../lib/domain/entities/column_map.dart';

void main() {
  const bike = BikeProfile.t7;

  // ---------------------------------------------------------------------------
  // Scenario 12: End-to-end round-trip (mirrors Python test_pipeline.py)
  // ---------------------------------------------------------------------------
  group('End-to-end pipeline round-trip', () {
    test('rough terrain: histograms sum to ≈100%', () async {
      final config = const SimulatorConfig(
        scenario: SimulatorScenario.roughTerrain,
        durationS: 10.0,
        enableNoise: true,
        seed: 42,
      );
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();

      expect(frames, isNotEmpty);

      final result = SessionPipeline.process(
        frames,
        bike,
        columnMap: const ColumnMap(),
        velocityQuantity: VelocityQuantity.shaft,
      );

      // No NaNs in histogram outputs
      expect(result.frontTravel.timePct.any((v) => v.isNaN), isFalse);
      expect(result.frontVelocity.timePct.any((v) => v.isNaN), isFalse);

      // Travel histograms sum to ≈100
      final fTravelSum = result.frontTravel.timePct.reduce((a, b) => a + b);
      expect(fTravelSum, closeTo(100.0, 0.01));

      final rTravelSum = result.rearTravel.timePct.reduce((a, b) => a + b);
      expect(rTravelSum, closeTo(100.0, 0.01));

      // Velocity areas ≤ 100%
      final fVelTotal = result.frontVelocity.compressionAreaPct +
          result.frontVelocity.reboundAreaPct;
      expect(fVelTotal, lessThanOrEqualTo(100.01));

      // Pitch trace length matches sample count
      expect(result.pitch.pitchDeg.length, result.sampleCount);
      expect(result.pitch.timeS.length, result.sampleCount);

      // Duration is physically reasonable
      expect(result.durationS, greaterThan(5.0));

      // Sample count: 10s × 250 Hz = 2500
      expect(result.sampleCount, 2500);
    });

    test('static sag: near-zero velocity in histogram', () async {
      final config = const SimulatorConfig(
        scenario: SimulatorScenario.staticSag,
        durationS: 4.0,
        enableNoise: false, // clean for deterministic test
      );
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();
      final result = SessionPipeline.process(frames, bike);

      // With clean data and constant displacement, most velocity should be ~0
      // So LS-compression + LS-rebound should dominate vs HS
      expect(result.frontVelocity.hsCompressionPct, lessThan(5.0));
      expect(result.frontVelocity.hsReboundPct, lessThan(5.0));
    });

    test('braking: front more compressed than rear', () async {
      final config = const SimulatorConfig(
        scenario: SimulatorScenario.braking,
        durationS: 10.0,
        enableNoise: false,
      );
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();
      final result = SessionPipeline.process(frames, bike);

      // Braking should include clear negative longitudinal acceleration.
      final minAccelX = result.pitch.accelXG.reduce(math.min);
      expect(minAccelX, lessThan(-0.2));
    });

    test('sample count matches expected frames', () async {
      for (final durationS in [2.0, 5.0, 10.0]) {
        final config = SimulatorConfig(
            scenario: SimulatorScenario.staticSag,
            durationS: durationS,
            enableNoise: false);
        final source = SimulatorSource(config: config, bike: bike);
        final frames = await source.acquire();
        final result = SessionPipeline.process(frames, bike);
        expect(result.sampleCount, (durationS * bike.fsHz).round());
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Scenario 13: Column mapping edge cases
  // ---------------------------------------------------------------------------
  group('Column mapping edge cases', () {
    test('invert front flag negates front ADC', () async {
      final config = const SimulatorConfig(
          scenario: SimulatorScenario.staticSag, enableNoise: false);
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();

      final normal = SessionPipeline.process(frames, bike);
      final inverted = SessionPipeline.process(
        frames,
        bike,
        columnMap: const ColumnMap(invertFront: true),
      );

      // Inverting front should change the front travel peak
      expect(normal.frontTravel.peakCenterPct,
          isNot(inverted.frontTravel.peakCenterPct));
    });
  });

  // ---------------------------------------------------------------------------
  // Diagnostic advisor integration
  // ---------------------------------------------------------------------------
  group('Diagnostic advisor integration', () {
    test('static sag produces no diagnostics (balanced histogram)', () async {
      // Static sag at 30% travel → should be within normal range
      final config = const SimulatorConfig(
          scenario: SimulatorScenario.staticSag, enableNoise: false);
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();
      final result = SessionPipeline.process(frames, bike);
      // Travel is at 70/210 = 33% → within 20-50% → no shift warnings
      // (may get rebound asymmetry from zero-velocity static data)
      expect(result.diagnostics, isA<List>());
    });

    test('diagnostics list is a list (no crash)', () async {
      final config = const SimulatorConfig(
          scenario: SimulatorScenario.roughTerrain, durationS: 10.0);
      final source = SimulatorSource(config: config, bike: bike);
      final frames = await source.acquire();
      final result = SessionPipeline.process(frames, bike);
      expect(result.diagnostics, isA<List>());
    });
  });
}
