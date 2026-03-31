import 'dart:convert';

/// Named simulator scenarios — mirrors the Python daq-simulate CLI scenarios.
enum SimulatorScenario {
  staticSag('static_sag', 'Static Sag'),
  braking('braking', 'Hard Braking'),
  squareEdgeHit('square_edge', 'Square Edge Hit'),
  repeatedBumps('repeated_bumps', 'Repeated Bumps'),
  jumpAndLanding('jump_landing', 'Jump and Landing'),
  roughTerrain('rough_terrain', 'Rough Terrain');

  const SimulatorScenario(this.id, this.label);

  /// Stable identifier used in JSON persistence.
  final String id;

  /// Human-readable label for UI display.
  final String label;

  static SimulatorScenario fromId(String id) =>
      values.firstWhere((s) => s.id == id,
          orElse: () => SimulatorScenario.staticSag);
}

/// Configuration for a simulator data acquisition run.
///
/// Mirrors the CLI options of the Python daq-simulate tool, exposed via
/// the in-app Debug Simulator screen so developers can configure any
/// scenario without leaving the app.
class SimulatorConfig {
  const SimulatorConfig({
    this.scenario = SimulatorScenario.staticSag,
    this.durationS = 10.0,
    this.enableNoise = true,
    this.seed = 42,
    this.frontNoiseRms = 1.5,
    this.rearNoiseRms = 1.5,
    this.gyroNoiseRms = 0.05,
    this.gyroBiasDegS = 0.08,
  });

  final SimulatorScenario scenario;
  final double durationS;
  final bool enableNoise;

  /// Random seed for reproducible noise (same seed → same output).
  final int seed;

  /// Front ADC noise amplitude [LSB RMS].
  final double frontNoiseRms;

  /// Rear ADC noise amplitude [LSB RMS].
  final double rearNoiseRms;

  /// Gyro noise amplitude [counts RMS].
  final double gyroNoiseRms;

  /// Constant gyro bias [deg/s].
  final double gyroBiasDegS;

  SimulatorConfig copyWith({
    SimulatorScenario? scenario,
    double? durationS,
    bool? enableNoise,
    int? seed,
    double? frontNoiseRms,
    double? rearNoiseRms,
    double? gyroNoiseRms,
    double? gyroBiasDegS,
  }) =>
      SimulatorConfig(
        scenario: scenario ?? this.scenario,
        durationS: durationS ?? this.durationS,
        enableNoise: enableNoise ?? this.enableNoise,
        seed: seed ?? this.seed,
        frontNoiseRms: frontNoiseRms ?? this.frontNoiseRms,
        rearNoiseRms: rearNoiseRms ?? this.rearNoiseRms,
        gyroNoiseRms: gyroNoiseRms ?? this.gyroNoiseRms,
        gyroBiasDegS: gyroBiasDegS ?? this.gyroBiasDegS,
      );

  Map<String, dynamic> toJson() => {
        'scenario': scenario.id,
        'durationS': durationS,
        'enableNoise': enableNoise,
        'seed': seed,
        'frontNoiseRms': frontNoiseRms,
        'rearNoiseRms': rearNoiseRms,
        'gyroNoiseRms': gyroNoiseRms,
        'gyroBiasDegS': gyroBiasDegS,
      };

  factory SimulatorConfig.fromJson(Map<String, dynamic> json) =>
      SimulatorConfig(
        scenario: SimulatorScenario.fromId(json['scenario'] as String? ?? ''),
        durationS: (json['durationS'] as num? ?? 10.0).toDouble(),
        enableNoise: json['enableNoise'] as bool? ?? true,
        seed: json['seed'] as int? ?? 42,
        frontNoiseRms: (json['frontNoiseRms'] as num? ?? 1.5).toDouble(),
        rearNoiseRms: (json['rearNoiseRms'] as num? ?? 1.5).toDouble(),
        gyroNoiseRms: (json['gyroNoiseRms'] as num? ?? 0.05).toDouble(),
        gyroBiasDegS: (json['gyroBiasDegS'] as num? ?? 0.08).toDouble(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory SimulatorConfig.fromJsonString(String s) =>
      SimulatorConfig.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  String toString() =>
      'SimulatorConfig(scenario=${scenario.label}, duration=${durationS}s, '
      'noise=${enableNoise ? 'on' : 'off'}, seed=$seed)';
}
