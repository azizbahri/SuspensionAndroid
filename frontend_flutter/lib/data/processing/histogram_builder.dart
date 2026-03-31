import 'dart:typed_data';

import '../../core/utils/math_utils.dart';
import '../../domain/entities/analysis_result.dart';

/// Travel and velocity histogram builders.
///
/// Port of backend/app/processing/histograms.py
///
/// Travel histogram:
///   X: 0–100 % travel in 10 % bins  (centers: 5, 15, …, 95)
///   Y: % of ride time in each bin
///
/// Velocity histogram:
///   X: −1500 to +1500 mm/s in 50 mm/s bins
///   Y: % of ride time in each bin
///   Positive = rebound,  Negative = compression
///   LS threshold default: |v| < 150 mm/s
class HistogramBuilder {
  HistogramBuilder._();

  // ---------------------------------------------------------------------------
  // Travel histogram
  // ---------------------------------------------------------------------------

  static final List<double> _travelEdges = List.generate(
    11,
    (i) => i * 10.0,
  ); // [0, 10, 20, ..., 100]

  /// Build a time-percentage travel histogram from travel percentage values.
  ///
  /// [travelPct] — travel values in percent (0–100).
  /// [lsThreshold] — not used for travel, kept for API symmetry.
  static TravelHistogram buildTravelHistogram(
    Float64List travelPct, {
    double lsThreshold = 80.0,
  }) {
    final valid = <double>[];
    for (final v in travelPct) {
      if (!v.isNaN && !v.isInfinite) valid.add(v);
    }

    final counts = MathUtils.histogram(valid, _travelEdges);
    final total = counts.reduce((a, b) => a + b);
    final norm = total > 0 ? 100.0 / total : 1.0;

    final timePct = counts.map((c) => c * norm).toList();
    final centers = List.generate(10, (i) => i * 10.0 + 5.0);

    int peakIdx = 0;
    for (int i = 1; i < counts.length; i++) {
      if (counts[i] > counts[peakIdx]) peakIdx = i;
    }

    double pctAbove80 = 0;
    for (int i = 0; i < centers.length; i++) {
      if (centers[i] >= 80.0) pctAbove80 += timePct[i];
    }

    return TravelHistogram(
      centersPct: centers,
      timePct: timePct,
      peakCenterPct: centers[peakIdx],
      pctAbove80: pctAbove80,
    );
  }

  // ---------------------------------------------------------------------------
  // Velocity histogram
  // ---------------------------------------------------------------------------

  /// Bin edges: −1500 to +1500 mm/s in 50 mm/s steps (61 edges, 60 bins).
  static final List<double> _velEdges = List.generate(
    61,
    (i) => -1500.0 + i * 50.0,
  );

  /// Bin centers: −1475, −1425, …, +1475 mm/s.
  static final List<double> _velCenters = List.generate(
    60,
    (i) => -1475.0 + i * 50.0,
  );

  /// Build a time-percentage velocity histogram with LS/HS breakdown.
  ///
  /// [velocityMmS] — velocity in mm/s (negative = compression, positive = rebound).
  /// [lsThreshold] — low/high-speed boundary in mm/s (default 150 mm/s).
  static VelocityHistogram buildVelocityHistogram(
    Float64List velocityMmS, {
    double lsThreshold = 150.0,
  }) {
    final valid = <double>[];
    for (final v in velocityMmS) {
      if (!v.isNaN && !v.isInfinite) valid.add(v);
    }

    final counts = MathUtils.histogram(valid, _velEdges);
    final total = counts.reduce((a, b) => a + b);
    final norm = total > 0 ? 100.0 / total : 1.0;

    final timePct = counts.map((c) => c * norm).toList();
    final centers = _velCenters;

    double compressionArea = 0, reboundArea = 0;
    double lsCompression = 0, hsCompression = 0;
    double lsRebound = 0, hsRebound = 0;

    for (int i = 0; i < centers.length; i++) {
      final c = centers[i];
      final t = timePct[i];
      if (c < 0) {
        compressionArea += t;
        if (c.abs() <= lsThreshold) {
          lsCompression += t;
        } else {
          hsCompression += t;
        }
      } else if (c > 0) {
        reboundArea += t;
        if (c <= lsThreshold) {
          lsRebound += t;
        } else {
          hsRebound += t;
        }
      }
    }

    return VelocityHistogram(
      centersMmS: centers,
      timePct: timePct,
      compressionAreaPct: compressionArea,
      reboundAreaPct: reboundArea,
      lsCompressionPct: lsCompression,
      hsCompressionPct: hsCompression,
      lsReboundPct: lsRebound,
      hsReboundPct: hsRebound,
    );
  }
}
