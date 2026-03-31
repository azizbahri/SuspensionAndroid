import 'dart:convert';

/// Immutable bike/sensor configuration profile.
///
/// Mirrors the Python backend BikeProfile Pydantic model 1:1.
/// All field names use camelCase in Dart; JSON serialisation uses snake_case
/// to match the stored format (same keys as the Python backend JSON files).
class BikeProfile {
  const BikeProfile({
    required this.name,
    required this.slug,
    this.wMaxFrontMm = 210.0,
    this.wMaxRearMm = 210.0,
    this.forkAngleDeg = 27.0,
    this.cFront = 42.0,
    this.v0Front = 0.50,
    this.cRear = 18.5,
    this.v0Rear = 0.40,
    this.linkageA = -0.015,
    this.linkageB = 4.20,
    this.linkageC = 0.0,
    this.adcBits = 12,
    this.vRef = 5.0,
    this.fsHz = 250.0,
    this.lpfCutoffDispHz = 20.0,
    this.lpfCutoffGyroHz = 10.0,
    this.complementaryAlpha = 0.98,
    this.stationarySamples = 250,
    this.gyroSensitivity = 16.4,
    this.accelSensitivity = 2048.0,
    this.lsThresholdMmS = 150.0,
  });

  // Identity
  final String name;
  final String slug;

  // Travel limits
  final double wMaxFrontMm;
  final double wMaxRearMm;

  // Geometry
  final double forkAngleDeg;

  // Front calibration: s = (V - v0Front) × cFront
  final double cFront;
  final double v0Front;

  // Rear calibration: s = (V - v0Rear) × cRear
  final double cRear;
  final double v0Rear;

  // Linkage polynomial: W = linkageA×s² + linkageB×s + linkageC
  final double linkageA;
  final double linkageB;
  final double linkageC;

  // ADC
  final int adcBits;
  final double vRef;

  // Acquisition
  final double fsHz;

  // Filter cutoffs
  final double lpfCutoffDispHz;
  final double lpfCutoffGyroHz;

  // Complementary filter
  final double complementaryAlpha;
  final int stationarySamples;

  // IMU sensitivity
  final double gyroSensitivity;
  final double accelSensitivity;

  // Advisor threshold
  final double lsThresholdMmS;

  // ---------------------------------------------------------------------------
  // Defaults
  // ---------------------------------------------------------------------------

  /// Pre-populated Yamaha Ténéré 700 profile.
  static const BikeProfile t7 = BikeProfile(
    name: "Yamaha Ténéré 700",
    slug: "t7",
  );

  // ---------------------------------------------------------------------------
  // Value-object helpers
  // ---------------------------------------------------------------------------

  BikeProfile copyWith({
    String? name,
    String? slug,
    double? wMaxFrontMm,
    double? wMaxRearMm,
    double? forkAngleDeg,
    double? cFront,
    double? v0Front,
    double? cRear,
    double? v0Rear,
    double? linkageA,
    double? linkageB,
    double? linkageC,
    int? adcBits,
    double? vRef,
    double? fsHz,
    double? lpfCutoffDispHz,
    double? lpfCutoffGyroHz,
    double? complementaryAlpha,
    int? stationarySamples,
    double? gyroSensitivity,
    double? accelSensitivity,
    double? lsThresholdMmS,
  }) =>
      BikeProfile(
        name: name ?? this.name,
        slug: slug ?? this.slug,
        wMaxFrontMm: wMaxFrontMm ?? this.wMaxFrontMm,
        wMaxRearMm: wMaxRearMm ?? this.wMaxRearMm,
        forkAngleDeg: forkAngleDeg ?? this.forkAngleDeg,
        cFront: cFront ?? this.cFront,
        v0Front: v0Front ?? this.v0Front,
        cRear: cRear ?? this.cRear,
        v0Rear: v0Rear ?? this.v0Rear,
        linkageA: linkageA ?? this.linkageA,
        linkageB: linkageB ?? this.linkageB,
        linkageC: linkageC ?? this.linkageC,
        adcBits: adcBits ?? this.adcBits,
        vRef: vRef ?? this.vRef,
        fsHz: fsHz ?? this.fsHz,
        lpfCutoffDispHz: lpfCutoffDispHz ?? this.lpfCutoffDispHz,
        lpfCutoffGyroHz: lpfCutoffGyroHz ?? this.lpfCutoffGyroHz,
        complementaryAlpha: complementaryAlpha ?? this.complementaryAlpha,
        stationarySamples: stationarySamples ?? this.stationarySamples,
        gyroSensitivity: gyroSensitivity ?? this.gyroSensitivity,
        accelSensitivity: accelSensitivity ?? this.accelSensitivity,
        lsThresholdMmS: lsThresholdMmS ?? this.lsThresholdMmS,
      );

  // ---------------------------------------------------------------------------
  // JSON
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toJson() => {
        'name': name,
        'slug': slug,
        'w_max_front_mm': wMaxFrontMm,
        'w_max_rear_mm': wMaxRearMm,
        'fork_angle_deg': forkAngleDeg,
        'c_front': cFront,
        'v0_front': v0Front,
        'c_rear': cRear,
        'v0_rear': v0Rear,
        'linkage_a': linkageA,
        'linkage_b': linkageB,
        'linkage_c': linkageC,
        'adc_bits': adcBits,
        'v_ref': vRef,
        'fs_hz': fsHz,
        'lpf_cutoff_disp_hz': lpfCutoffDispHz,
        'lpf_cutoff_gyro_hz': lpfCutoffGyroHz,
        'complementary_alpha': complementaryAlpha,
        'stationary_samples': stationarySamples,
        'gyro_sensitivity': gyroSensitivity,
        'accel_sensitivity': accelSensitivity,
        'ls_threshold_mm_s': lsThresholdMmS,
      };

  factory BikeProfile.fromJson(Map<String, dynamic> json) => BikeProfile(
        name: json['name'] as String,
        slug: json['slug'] as String,
        wMaxFrontMm: (json['w_max_front_mm'] as num? ?? 210.0).toDouble(),
        wMaxRearMm: (json['w_max_rear_mm'] as num? ?? 210.0).toDouble(),
        forkAngleDeg: (json['fork_angle_deg'] as num? ?? 27.0).toDouble(),
        cFront: (json['c_front'] as num? ?? 42.0).toDouble(),
        v0Front: (json['v0_front'] as num? ?? 0.5).toDouble(),
        cRear: (json['c_rear'] as num? ?? 18.5).toDouble(),
        v0Rear: (json['v0_rear'] as num? ?? 0.4).toDouble(),
        linkageA: (json['linkage_a'] as num? ?? -0.015).toDouble(),
        linkageB: (json['linkage_b'] as num? ?? 4.20).toDouble(),
        linkageC: (json['linkage_c'] as num? ?? 0.0).toDouble(),
        adcBits: json['adc_bits'] as int? ?? 12,
        vRef: (json['v_ref'] as num? ?? 5.0).toDouble(),
        fsHz: (json['fs_hz'] as num? ?? 250.0).toDouble(),
        lpfCutoffDispHz:
            (json['lpf_cutoff_disp_hz'] as num? ?? 20.0).toDouble(),
        lpfCutoffGyroHz:
            (json['lpf_cutoff_gyro_hz'] as num? ?? 10.0).toDouble(),
        complementaryAlpha:
            (json['complementary_alpha'] as num? ?? 0.98).toDouble(),
        stationarySamples: json['stationary_samples'] as int? ?? 250,
        gyroSensitivity: (json['gyro_sensitivity'] as num? ?? 16.4).toDouble(),
        accelSensitivity:
            (json['accel_sensitivity'] as num? ?? 2048.0).toDouble(),
        lsThresholdMmS:
            (json['ls_threshold_mm_s'] as num? ?? 150.0).toDouble(),
      );

  String toJsonString() => jsonEncode(toJson());

  factory BikeProfile.fromJsonString(String s) =>
      BikeProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BikeProfile &&
          runtimeType == other.runtimeType &&
          slug == other.slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'BikeProfile($name [$slug])';
}
