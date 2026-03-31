import 'dart:math' as math;

/// Pure math utilities used by processing and simulator layers.
/// No Flutter imports — safe to use in domain and data layers.
class MathUtils {
  MathUtils._();

  // ---------------------------------------------------------------------------
  // Polynomial fitting
  // ---------------------------------------------------------------------------

  /// Least-squares linear fit: y = m*x + b.
  ///
  /// Returns [m, b] (highest power first, same convention as numpy.polyfit).
  /// Throws [ArgumentError] if fewer than 2 points are given.
  static List<double> polyfit1(List<double> x, List<double> y) {
    assert(x.length == y.length, 'x and y must have the same length');
    final n = x.length;
    if (n < 2) throw ArgumentError('Need at least 2 points for linear fit');

    double sx = 0, sy = 0, sxx = 0, sxy = 0;
    for (int i = 0; i < n; i++) {
      sx += x[i];
      sy += y[i];
      sxx += x[i] * x[i];
      sxy += x[i] * y[i];
    }
    final denom = n * sxx - sx * sx;
    if (denom.abs() < 1e-12) {
      throw ArgumentError('All x values are identical — cannot fit a line');
    }
    final m = (n * sxy - sx * sy) / denom;
    final b = (sy - m * sx) / n;
    return [m, b];
  }

  /// Least-squares quadratic fit: y = a*x^2 + b*x + c.
  ///
  /// Returns [a, b, c] (highest power first, same convention as numpy.polyfit).
  /// Throws [ArgumentError] if fewer than 3 points are given.
  static List<double> polyfit2(List<double> x, List<double> y) {
    assert(x.length == y.length, 'x and y must have the same length');
    final n = x.length;
    if (n < 3) throw ArgumentError('Need at least 3 points for quadratic fit');

    // Build the normal equation matrix for [a, b, c]:
    // [Σx^4  Σx^3  Σx^2] [a]   [Σx^2*y]
    // [Σx^3  Σx^2  Σx  ] [b] = [Σx*y  ]
    // [Σx^2  Σx    n   ] [c]   [Σy    ]
    double s0 = n.toDouble();
    double s1 = 0, s2 = 0, s3 = 0, s4 = 0;
    double r0 = 0, r1 = 0, r2 = 0;
    for (int i = 0; i < n; i++) {
      final xi = x[i];
      final yi = y[i];
      final xi2 = xi * xi;
      final xi3 = xi2 * xi;
      final xi4 = xi3 * xi;
      s1 += xi;
      s2 += xi2;
      s3 += xi3;
      s4 += xi4;
      r0 += xi2 * yi;
      r1 += xi * yi;
      r2 += yi;
    }

    // Gaussian elimination on the 3×3 augmented matrix.
    // Row 0: [s4, s3, s2 | r0]
    // Row 1: [s3, s2, s1 | r1]
    // Row 2: [s2, s1, s0 | r2]
    final A = [
      [s4, s3, s2, r0],
      [s3, s2, s1, r1],
      [s2, s1, s0, r2],
    ];

    // Forward elimination
    for (int col = 0; col < 3; col++) {
      // Pivot
      int pivot = col;
      for (int row = col + 1; row < 3; row++) {
        if (A[row][col].abs() > A[pivot][col].abs()) pivot = row;
      }
      final tmp = A[col];
      A[col] = A[pivot];
      A[pivot] = tmp;

      final diag = A[col][col];
      if (diag.abs() < 1e-15) {
        throw ArgumentError('Singular matrix — x values may be collinear');
      }
      for (int row = col + 1; row < 3; row++) {
        final factor = A[row][col] / diag;
        for (int j = col; j <= 3; j++) {
          A[row][j] -= factor * A[col][j];
        }
      }
    }

    // Back substitution
    final coeffs = List<double>.filled(3, 0);
    for (int i = 2; i >= 0; i--) {
      coeffs[i] = A[i][3];
      for (int j = i + 1; j < 3; j++) {
        coeffs[i] -= A[i][j] * coeffs[j];
      }
      coeffs[i] /= A[i][i];
    }
    return coeffs; // [a, b, c]
  }

  // ---------------------------------------------------------------------------
  // Statistics
  // ---------------------------------------------------------------------------

  /// Population standard deviation of [data].
  static double standardDeviation(List<double> data) {
    if (data.isEmpty) return 0.0;
    final mean = data.reduce((a, b) => a + b) / data.length;
    final variance =
        data.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) /
            data.length;
    return math.sqrt(variance);
  }

  /// Mean of [data]. Returns 0 if empty.
  static double mean(List<double> data) {
    if (data.isEmpty) return 0.0;
    return data.reduce((a, b) => a + b) / data.length;
  }

  /// Root-mean-square of residuals.
  static double rmse(List<double> actual, List<double> predicted) {
    assert(actual.length == predicted.length);
    if (actual.isEmpty) return 0.0;
    double sum = 0;
    for (int i = 0; i < actual.length; i++) {
      final diff = actual[i] - predicted[i];
      sum += diff * diff;
    }
    return math.sqrt(sum / actual.length);
  }

  // ---------------------------------------------------------------------------
  // Histogram
  // ---------------------------------------------------------------------------

  /// Count values into bins defined by [edges] (length = nBins + 1).
  ///
  /// Follows numpy.histogram convention: left-closed, right-open for all bins
  /// except the last which is closed on both sides.
  static List<int> histogram(List<double> data, List<double> edges) {
    final nBins = edges.length - 1;
    final counts = List<int>.filled(nBins, 0);
    for (final x in data) {
      if (x.isNaN || x.isInfinite) continue;
      _binSearch(x, edges, nBins, counts);
    }
    return counts;
  }

  static void _binSearch(
      double x, List<double> edges, int nBins, List<int> counts) {
    if (x < edges[0] || x > edges[nBins]) return;
    // Binary search for the bin
    int lo = 0, hi = nBins - 1;
    while (lo < hi) {
      final mid = (lo + hi) ~/ 2;
      if (x < edges[mid + 1]) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    // Last bin is closed on both sides
    if (lo == nBins - 1 && x <= edges[nBins]) {
      counts[lo]++;
    } else if (x >= edges[lo] && x < edges[lo + 1]) {
      counts[lo]++;
    }
  }

  // ---------------------------------------------------------------------------
  // Clipping
  // ---------------------------------------------------------------------------

  /// Clip [value] to the range [min, max].
  static double clip(double value, double min, double max) =>
      value < min ? min : (value > max ? max : value);
}
