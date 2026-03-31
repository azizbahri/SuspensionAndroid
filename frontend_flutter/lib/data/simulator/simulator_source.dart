import 'dart:math' as math;

import '../../domain/entities/bike_profile.dart';
import '../hardware/daq_frame.dart';
import '../hardware/data_source.dart';
import 'physics_model.dart';
import 'sensor_model.dart';
import 'simulator_config.dart';

/// [DataSource] implementation that generates physically realistic [DaqFrame]s
/// from the built-in [PhysicsModel] + [SensorModel].
///
/// This is the primary debug/development data source. It accepts a
/// [SimulatorConfig] (scenario, duration, noise parameters) and a
/// [BikeProfile] (calibration constants used for sensor inversion).
///
/// Usage:
/// ```dart
/// final source = SimulatorSource(
///   config: SimulatorConfig(scenario: SimulatorScenario.braking, durationS: 10),
///   bike: t7Profile,
/// );
/// final frames = await source.acquire();
/// ```
class SimulatorSource extends DataSource {
  SimulatorSource({
    required this.config,
    required this.bike,
  });

  final SimulatorConfig config;
  final BikeProfile bike;

  @override
  String get name => 'Simulator — ${config.scenario.label}';

  @override
  bool get supportsStreaming => false;

  @override
  Future<List<DaqFrame>> acquire() async {
    // Run physics model for the selected scenario.
    final model = PhysicsModel(
      fsHz: bike.fsHz,
      durationS: config.durationS,
      linkageA: bike.linkageA,
      linkageB: bike.linkageB,
      linkageC: bike.linkageC,
    );

    late final StateDict state;
    switch (config.scenario) {
      case SimulatorScenario.staticSag:
        state = model.staticSag();
      case SimulatorScenario.braking:
        state = model.brakingEvent();
      case SimulatorScenario.squareEdgeHit:
        state = model.squareEdgeHit();
      case SimulatorScenario.repeatedBumps:
        state = model.repeatedBumps();
      case SimulatorScenario.jumpAndLanding:
        state = model.jumpAndLanding();
      case SimulatorScenario.roughTerrain:
        state = model.roughTerrain(seed: config.seed);
    }

    // Apply sensor model (invert calibration chain → ADC counts).
    final sensor = SensorModel(bike);
    final noiseConfig = config.enableNoise
        ? NoiseConfig(
            frontAdcRms: config.frontNoiseRms,
            rearAdcRms: config.rearNoiseRms,
            gyroRms: config.gyroNoiseRms,
            gyroBiasDegS: config.gyroBiasDegS,
            seed: config.seed,
          )
        : const NoiseConfig(
            frontAdcRms: 0,
            rearAdcRms: 0,
            gyroRms: 0,
            gyroBiasDegS: 0,
          );

    var frontRaw = sensor.frontAdc(state.wFrontTrue);
    var rearRaw = sensor.rearAdc(state.sRearTrue);
    var gyroY = sensor.gyroYRaw(
      state.omegaYTrue,
      biasDegS: noiseConfig.gyroBiasDegS,
    );
    final (:ax, :ay, :az) = sensor.accelRaw(
      state.accelXTrue,
      state.accelYTrue,
      state.accelZTrue,
    );

    // Inject Gaussian noise
    final rng = math.Random(noiseConfig.seed);
    frontRaw = addGaussianNoiseInt(frontRaw, noiseConfig.frontAdcRms, rng);
    rearRaw = addGaussianNoiseInt(rearRaw, noiseConfig.rearAdcRms, rng);
    gyroY = addGaussianNoiseInt(gyroY, noiseConfig.gyroRms, rng);
    // Accel noise is typically small — skip for simplicity (can add later)

    // Assemble DaqFrame list
    final n = state.length;
    final frames = List<DaqFrame>.generate(n, (i) {
      return DaqFrame(
        timeS: state.t[i],
        frontRaw: frontRaw[i],
        rearRaw: rearRaw[i],
        gyroYRaw: gyroY[i],
        accelXRaw: ax[i],
        accelYRaw: ay[i],
        accelZRaw: az[i],
      );
    });
    return frames;
  }
}
