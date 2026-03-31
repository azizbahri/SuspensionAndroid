import 'dart:math' as math;
import 'dart:typed_data';

/// ADC counts → wheel travel in mm.
///
/// Port of backend/app/processing/displacement.py
///
/// Signal chain:
///   ADC counts → voltage → fork stroke → wheel travel (front)
///   ADC counts → voltage → shock stroke → wheel travel (rear, linkage polynomial)
class DisplacementProcessor {
  DisplacementProcessor._();

  // ---------------------------------------------------------------------------
  // ADC → Voltage
  // ---------------------------------------------------------------------------

  /// Convert raw ADC counts to voltage [V].
  ///
  /// [adcCounts] — integer ADC values.
  /// [adcBits] — resolution (default 12 → full-scale = 4095).
  /// [vRef] — reference voltage in volts (default 5 V).
  static Float64List adcToVoltage(
    List<int> adcCounts, {
    int adcBits = 12,
    double vRef = 5.0,
  }) {
    final fullScale = (1 << adcBits) - 1;
    final result = Float64List(adcCounts.length);
    for (int i = 0; i < adcCounts.length; i++) {
      result[i] = adcCounts[i] / fullScale * vRef;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Front fork (direct-acting telescopic)
  // ---------------------------------------------------------------------------

  /// Voltage → fork stroke [mm]:  s = (V - V0_front) × C_front
  static Float64List frontStroke(
    Float64List voltage, {
    required double v0Front,
    required double cFront,
  }) {
    final result = Float64List(voltage.length);
    for (int i = 0; i < voltage.length; i++) {
      result[i] = (voltage[i] - v0Front) * cFront;
    }
    return result;
  }

  /// Fork stroke → vertical wheel travel [mm]:  W = s × cos(θ)
  ///
  /// [forkAngleDeg] — fork rake angle from vertical in degrees.
  static Float64List frontTravel(
    Float64List strokeMm, {
    required double forkAngleDeg,
  }) {
    final cosTheta = math.cos(math.pi / 180.0 * forkAngleDeg);
    final result = Float64List(strokeMm.length);
    for (int i = 0; i < strokeMm.length; i++) {
      result[i] = strokeMm[i] * cosTheta;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Rear shock (linkage-driven)
  // ---------------------------------------------------------------------------

  /// Voltage → shock stroke [mm]:  s = (V - V0_rear) × C_rear
  static Float64List rearStroke(
    Float64List voltage, {
    required double v0Rear,
    required double cRear,
  }) {
    final result = Float64List(voltage.length);
    for (int i = 0; i < voltage.length; i++) {
      result[i] = (voltage[i] - v0Rear) * cRear;
    }
    return result;
  }

  /// Shock stroke → wheel travel [mm] via linkage polynomial:
  ///   W = a·s² + b·s + c
  static Float64List rearTravel(
    Float64List shockStrokeMm, {
    required double a,
    required double b,
    required double c,
  }) {
    final result = Float64List(shockStrokeMm.length);
    for (int i = 0; i < shockStrokeMm.length; i++) {
      final s = shockStrokeMm[i];
      result[i] = a * s * s + b * s + c;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Travel percentage
  // ---------------------------------------------------------------------------

  /// Normalize wheel travel to 0–100 % of available stroke.
  ///
  /// [wMaxMm] — maximum available wheel travel in mm.
  static Float64List travelPercent(
    Float64List wheelTravelMm, {
    required double wMaxMm,
  }) {
    final scale = 100.0 / wMaxMm;
    final result = Float64List(wheelTravelMm.length);
    for (int i = 0; i < wheelTravelMm.length; i++) {
      result[i] = wheelTravelMm[i] * scale;
    }
    return result;
  }
}
