import 'dart:math' as math;
import 'dart:typed_data';

import '../../domain/entities/bike_profile.dart';
import 'physics_model.dart';

/// Configuration for Gaussian noise injection.
///
/// Port of backend/app/simulator/noise.py → NoiseConfig
class NoiseConfig {
  const NoiseConfig({
    this.frontAdcRms = 1.5,
    this.rearAdcRms = 1.5,
    this.gyroRms = 0.05,
    this.gyroBiasDegS = 0.08,
    this.seed = 42,
  });

  final double frontAdcRms; // LSB RMS
  final double rearAdcRms; // LSB RMS
  final double gyroRms; // counts RMS
  final double gyroBiasDegS; // constant offset [deg/s]
  final int seed;

  static const NoiseConfig clean = NoiseConfig(
    frontAdcRms: 0,
    rearAdcRms: 0,
    gyroRms: 0,
    gyroBiasDegS: 0,
  );
}

/// Converts true physical states into synthetic raw ADC counts.
///
/// Port of backend/app/simulator/sensors.py → SensorModel
///
/// Inverts the calibration chain:
///   Front: W_front → s_f = W/cos(θ) → V = s_f/C_front + V0 → ADC
///   Rear:  W_rear  → s_rear (quadratic inverse) → V = s_rear/C_rear + V0 → ADC
///   Gyro:  omega_y → counts = (omega_y + bias) × sensitivity
///   Accel: a_g     → counts = a_g × sensitivity
class SensorModel {
  SensorModel(this.bike)
      : _maxAdc = (1 << bike.adcBits) - 1;

  final BikeProfile bike;
  final int _maxAdc;

  // ---------------------------------------------------------------------------
  // ADC quantisation
  // ---------------------------------------------------------------------------

  int _quantize(double voltage) {
    final counts = (voltage / bike.vRef * _maxAdc).round();
    return counts.clamp(0, _maxAdc);
  }

  // ---------------------------------------------------------------------------
  // Front potentiometer
  // ---------------------------------------------------------------------------

  /// Front wheel travel → 12-bit ADC count.
  Int32List frontAdc(Float64List wFrontMm) {
    final cosTheta = math.cos(math.pi / 180.0 * bike.forkAngleDeg);
    final result = Int32List(wFrontMm.length);
    for (int i = 0; i < wFrontMm.length; i++) {
      final sFork = wFrontMm[i] / cosTheta;
      final voltage = sFork / bike.cFront + bike.v0Front;
      result[i] = _quantize(voltage);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // Rear potentiometer
  // ---------------------------------------------------------------------------

  /// Rear shock stroke → 12-bit ADC count (uses pre-computed shock stroke).
  Int32List rearAdc(Float64List sRearMm) {
    final result = Int32List(sRearMm.length);
    for (int i = 0; i < sRearMm.length; i++) {
      final voltage = sRearMm[i] / bike.cRear + bike.v0Rear;
      result[i] = _quantize(voltage);
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // IMU — gyroscope
  // ---------------------------------------------------------------------------

  /// Pitch rate [deg/s] + bias → signed int16 gyro counts.
  Int32List gyroYRaw(Float64List omegaDegS, {double biasDegS = 0.08}) {
    final result = Int32List(omegaDegS.length);
    for (int i = 0; i < omegaDegS.length; i++) {
      result[i] = ((omegaDegS[i] + biasDegS) * bike.gyroSensitivity).round();
    }
    return result;
  }

  // ---------------------------------------------------------------------------
  // IMU — accelerometer
  // ---------------------------------------------------------------------------

  /// Accelerations [m/s²] → signed int16 counts (g-normalised).
  ({Int32List ax, Int32List ay, Int32List az}) accelRaw(
    Float64List axMs2,
    Float64List ayMs2,
    Float64List azMs2, {
    double grav = 9.80665,
  }) {
    final n = axMs2.length;
    final sens = bike.accelSensitivity;
    final ax = Int32List(n);
    final ay = Int32List(n);
    final az = Int32List(n);
    for (int i = 0; i < n; i++) {
      ax[i] = (axMs2[i] / grav * sens).round();
      ay[i] = (ayMs2[i] / grav * sens).round();
      az[i] = (azMs2[i] / grav * sens).round();
    }
    return (ax: ax, ay: ay, az: az);
  }
}

// ---------------------------------------------------------------------------
// Gaussian noise injection
// ---------------------------------------------------------------------------

/// Add zero-mean Gaussian noise to an integer array.
Int32List addGaussianNoiseInt(Int32List signal, double rms, math.Random rng) {
  if (rms == 0.0) return signal;
  final result = Int32List(signal.length);
  for (int i = 0; i < signal.length; i++) {
    result[i] =
        (signal[i] + _nextGaussian(rng) * rms).round();
  }
  return result;
}

/// Box-Muller Gaussian sample.
double _nextGaussian(math.Random rng) {
  double u1;
  do {
    u1 = rng.nextDouble();
  } while (u1 == 0.0);
  final u2 = rng.nextDouble();
  return math.sqrt(-2.0 * math.log(u1)) * math.cos(2.0 * math.pi * u2);
}
