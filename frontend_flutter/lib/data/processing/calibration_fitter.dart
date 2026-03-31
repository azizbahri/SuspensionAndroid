import '../../core/utils/math_utils.dart';

/// Sensor calibration fitting routines.
///
/// Port of backend/app/processing/calibration.py
///
/// Front linear calibration:
///   s = C_cal × (V − V0)
///   → polyfit(V, s, deg=1) → [m, b]
///   → C_cal = m,  V0 = −b/m,  RMSE in mm
///
/// Rear linkage polynomial:
///   W = a·s² + b·s + c
///   → polyfit(s, W, deg=2) → [a, b, c],  RMSE in mm
class CalibrationFitter {
  CalibrationFitter._();

  // ---------------------------------------------------------------------------
  // Front fork — linear fit
  // ---------------------------------------------------------------------------

  /// Fit linear sensor transfer function: s = C_cal × (V − V0).
  ///
  /// Returns a [FrontCalibrationResult] with c_cal, v0, and RMSE.
  ///
  /// Throws [ArgumentError] if fewer than 2 data points are provided.
  static FrontCalibrationResult fitFrontLinear({
    required List<double> strokesMm,
    required List<double> voltagesV,
  }) {
    assert(strokesMm.length == voltagesV.length,
        'strokesMm and voltagesV must have the same length');
    if (strokesMm.length < 2) {
      throw ArgumentError(
          'Need at least 2 calibration points for linear front fit');
    }

    // polyfit(voltages, strokes, deg=1) → s = m*V + b
    final coeffs = MathUtils.polyfit1(voltagesV, strokesMm);
    final m = coeffs[0]; // slope = C_cal
    final b = coeffs[1]; // intercept

    final cCal = m;
    final v0 = m != 0.0 ? -b / m : 0.0;

    // RMSE
    final predicted =
        voltagesV.map((v) => m * v + b).toList();
    final rmse = MathUtils.rmse(strokesMm, predicted);

    return FrontCalibrationResult(cCal: cCal, v0: v0, rmseMm: rmse);
  }

  // ---------------------------------------------------------------------------
  // Rear linkage — quadratic fit
  // ---------------------------------------------------------------------------

  /// Fit quadratic linkage polynomial: W = a·s² + b·s + c.
  ///
  /// Returns a [RearCalibrationResult] with a, b, c, and RMSE.
  ///
  /// Throws [ArgumentError] if fewer than 3 data points are provided.
  static RearCalibrationResult fitRearLinkage({
    required List<double> shockStrokesMm,
    required List<double> wheelTravelsMm,
  }) {
    assert(shockStrokesMm.length == wheelTravelsMm.length,
        'shockStrokesMm and wheelTravelsMm must have the same length');
    if (shockStrokesMm.length < 3) {
      throw ArgumentError(
          'Need at least 3 calibration points for quadratic rear fit');
    }

    // polyfit(strokes, travels, deg=2) → W = a*s^2 + b*s + c
    final coeffs = MathUtils.polyfit2(shockStrokesMm, wheelTravelsMm);
    final a = coeffs[0];
    final b = coeffs[1];
    final c = coeffs[2];

    // RMSE
    final predicted = shockStrokesMm
        .map((s) => a * s * s + b * s + c)
        .toList();
    final rmse = MathUtils.rmse(wheelTravelsMm, predicted);

    return RearCalibrationResult(a: a, b: b, c: c, rmseMm: rmse);
  }
}

// ---------------------------------------------------------------------------
// Result value objects
// ---------------------------------------------------------------------------

/// Result of a front fork linear calibration fit.
class FrontCalibrationResult {
  const FrontCalibrationResult({
    required this.cCal,
    required this.v0,
    required this.rmseMm,
  });

  /// Calibration constant [mm/V] → use as BikeProfile.cFront.
  final double cCal;

  /// Zero-stroke voltage [V] → use as BikeProfile.v0Front.
  final double v0;

  /// Fit residual [mm].
  final double rmseMm;

  @override
  String toString() =>
      'FrontCal(cCal=${cCal.toStringAsFixed(2)}, v0=${v0.toStringAsFixed(3)}, rmse=${rmseMm.toStringAsFixed(3)} mm)';
}

/// Result of a rear linkage quadratic calibration fit.
class RearCalibrationResult {
  const RearCalibrationResult({
    required this.a,
    required this.b,
    required this.c,
    required this.rmseMm,
  });

  /// Quadratic coefficient a → use as BikeProfile.linkageA.
  final double a;

  /// Linear coefficient b → use as BikeProfile.linkageB.
  final double b;

  /// Constant term c → use as BikeProfile.linkageC.
  final double c;

  /// Fit residual [mm].
  final double rmseMm;

  @override
  String toString() =>
      'RearCal(a=${a.toStringAsFixed(4)}, b=${b.toStringAsFixed(3)}, c=${c.toStringAsFixed(3)}, rmse=${rmseMm.toStringAsFixed(3)} mm)';
}
