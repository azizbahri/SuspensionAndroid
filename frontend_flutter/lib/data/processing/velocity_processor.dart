import 'dart:math' as math;
import 'dart:typed_data';

import 'signal_filter.dart';

/// Velocity estimation from filtered displacement data.
///
/// Port of backend/app/processing/velocity.py
///
/// Pipeline:
///   W(t) → Butterworth LPF (zero-phase) → W_f(t) → backward difference → v(t)
///
/// Sign convention (matches Python):
///   negative = compression  (travel increases into stroke → negate dW/dt)
///   positive = rebound
class VelocityProcessor {
  VelocityProcessor._();

  // ---------------------------------------------------------------------------
  // Filtering
  // ---------------------------------------------------------------------------

  /// Apply zero-phase Butterworth LPF to a displacement signal.
  ///
  /// Returns [signalMm] unchanged if it is shorter than
  /// [SignalFilter.minSamples] (13 samples).
  static Float64List filterDisplacement(
    Float64List signalMm, {
    required double fsHz,
    double cutoffHz = 20.0,
  }) {
    final (:b, :a) = SignalFilter.butter(cutoffHz, fsHz);
    return SignalFilter.filtfilt(signalMm, b, a);
  }

  // ---------------------------------------------------------------------------
  // Differentiation
  // ---------------------------------------------------------------------------

  /// Backward-difference derivative.  First sample is set to 0.
  ///
  /// v[0] = 0,  v[n] = (signal[n] - signal[n-1]) / dt
  static Float64List _backwardDiff(Float64List signal, double dt) {
    final n = signal.length;
    final v = Float64List(n);
    v[0] = 0.0;
    for (int i = 1; i < n; i++) {
      v[i] = (signal[i] - signal[i - 1]) / dt;
    }
    return v;
  }

  // ---------------------------------------------------------------------------
  // Wheel velocity
  // ---------------------------------------------------------------------------

  /// Wheel velocity [mm/s] from filtered displacement.
  ///
  /// Sign: negative = compression (W increases into stroke → negate dW/dt).
  static Float64List wheelVelocity(
    Float64List filteredMm, {
    required double fsHz,
  }) {
    final dt = 1.0 / fsHz;
    final raw = _backwardDiff(filteredMm, dt);
    final result = Float64List(raw.length);
    for (int i = 0; i < raw.length; i++) {
      result[i] = -raw[i];
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Shaft velocity — front fork
  // ---------------------------------------------------------------------------

  /// Convert wheel velocity to fork-shaft velocity [mm/s].
  ///
  ///   v_shaft = v_wheel / cos(θ)
  static Float64List shaftVelocityFront(
    Float64List vWheelMmS, {
    required double forkAngleDeg,
  }) {
    final cosTheta = math.cos(math.pi / 180.0 * forkAngleDeg);
    final result = Float64List(vWheelMmS.length);
    for (int i = 0; i < vWheelMmS.length; i++) {
      result[i] = vWheelMmS[i] / cosTheta;
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Shaft velocity — rear damper
  // ---------------------------------------------------------------------------

  /// Rear damper shaft velocity [mm/s].
  ///
  /// Differentiates the calibrated shock stroke directly (not wheel travel)
  /// to bypass the non-constant linkage motion ratio.
  /// Sign: negative = compression.
  static Float64List shaftVelocityRear(
    Float64List shockStrokeMm, {
    required double fsHz,
    double cutoffHz = 20.0,
  }) {
    final filtered = filterDisplacement(shockStrokeMm,
        fsHz: fsHz, cutoffHz: cutoffHz);
    final raw = _backwardDiff(filtered, 1.0 / fsHz);
    final result = Float64List(raw.length);
    for (int i = 0; i < raw.length; i++) {
      result[i] = -raw[i];
    }
    return result;
  }
}
