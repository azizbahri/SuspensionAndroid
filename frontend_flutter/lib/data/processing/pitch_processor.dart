import 'dart:math' as math;
import 'dart:typed_data';

import 'signal_filter.dart';

/// Chassis pitch angle estimation via a complementary filter.
///
/// Port of backend/app/processing/pitch.py
///
/// Signal chain:
///   gyro_raw → deg/s → bias-correct → LPF ──┐
///   accel_raw → g → atan2 pitch ─────────────┤ → complementary filter → φ
///                                             └─ α·gyro_int + (1-α)·φ_acc
///
/// The complementary filter is ALWAYS used — gyro-only integration is never
/// used as a standalone, matching the Python design.
class PitchProcessor {
  PitchProcessor._();

  // ---------------------------------------------------------------------------
  // Gyroscope
  // ---------------------------------------------------------------------------

  /// Convert raw gyro counts to deg/s.
  ///
  /// MPU-6050-style sensitivity: counts / (deg/s).
  /// Default sensitivity = 16.4 counts/(deg/s) → ±2000 °/s range.
  static Float64List gyroToDegS(
    List<int> gyroRaw, {
    double sensitivity = 16.4,
  }) {
    final result = Float64List(gyroRaw.length);
    for (int i = 0; i < gyroRaw.length; i++) {
      result[i] = gyroRaw[i] / sensitivity;
    }
    return result;
  }

  /// Estimate and subtract zero-rate bias from the first [stationarySamples].
  ///
  /// Returns a record: ({corrected, bias}).
  static ({Float64List corrected, double bias}) removeBias(
    Float64List rateDegS, {
    int stationarySamples = 250,
  }) {
    final n = math.min(stationarySamples, rateDegS.length);
    double sum = 0;
    for (int i = 0; i < n; i++) {
      sum += rateDegS[i];
    }
    final bias = n > 0 ? sum / n : 0.0;
    final corrected = Float64List(rateDegS.length);
    for (int i = 0; i < rateDegS.length; i++) {
      corrected[i] = rateDegS[i] - bias;
    }
    return (corrected: corrected, bias: bias);
  }

  /// Low-pass filter the gyro pitch-rate signal.
  static Float64List filterGyro(
    Float64List rateDegS, {
    required double fsHz,
    double cutoffHz = 10.0,
  }) {
    final (:b, :a) = SignalFilter.butter(cutoffHz, fsHz);
    return SignalFilter.filtfilt(rateDegS, b, a);
  }

  // ---------------------------------------------------------------------------
  // Accelerometer — pitch from gravity
  // ---------------------------------------------------------------------------

  /// Gravity-derived pitch angle [degrees].
  ///
  ///   φ_acc = atan2(-ax, √(ay² + az²))
  ///
  /// [axG], [ayG], [azG] are accelerometer readings in units of g.
  static Float64List accelPitchDeg(
    Float64List axG,
    Float64List ayG,
    Float64List azG,
  ) {
    final n = axG.length;
    final result = Float64List(n);
    for (int i = 0; i < n; i++) {
      final lateral = ayG[i] * ayG[i] + azG[i] * azG[i];
      result[i] =
          math.atan2(-axG[i], math.sqrt(lateral)) * 180.0 / math.pi;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Complementary filter
  // ---------------------------------------------------------------------------

  /// Trapezoidal complementary filter for chassis pitch.
  ///
  ///   φ[n] = α·(φ[n-1] + 0.5·(ω_f[n] + ω_f[n-1])·dt) + (1-α)·φ_acc[n]
  ///
  /// α = 0.98 by default — gyro dominates short-term, accel corrects slow drift.
  static Float64List complementaryFilterPitch(
    Float64List omegaYFiltered,
    Float64List phiAcc, {
    required double fsHz,
    double alpha = 0.98,
    double initialDeg = 0.0,
  }) {
    final n = omegaYFiltered.length;
    final dt = 1.0 / fsHz;
    final phi = Float64List(n);
    phi[0] = initialDeg;
    final oneMinusAlpha = 1.0 - alpha;
    for (int i = 1; i < n; i++) {
      final gyroIncrement =
          0.5 * (omegaYFiltered[i] + omegaYFiltered[i - 1]) * dt;
      phi[i] =
          alpha * (phi[i - 1] + gyroIncrement) + oneMinusAlpha * phiAcc[i];
    }
    return phi;
  }

  // ---------------------------------------------------------------------------
  // Longitudinal acceleration
  // ---------------------------------------------------------------------------

  /// Convert raw accelerometer X counts to g units.
  static Float64List longitudinalAccelG(
    List<int> axRaw, {
    double accelSensitivity = 2048.0,
  }) {
    final result = Float64List(axRaw.length);
    for (int i = 0; i < axRaw.length; i++) {
      result[i] = axRaw[i] / accelSensitivity;
    }
    return result;
  }
}
