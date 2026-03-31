import 'dart:math' as math;
import 'dart:typed_data';

/// Butterworth IIR low-pass filter — 2nd order, zero-phase (filtfilt).
///
/// Port of scipy.signal.butter (N=2, btype='low') +
///      scipy.signal.filtfilt used in the Python backend.
///
/// The filter is always 2nd order because that matches the Python codebase.
/// Coefficients are derived via the bilinear transform with frequency prewarping.
class SignalFilter {
  SignalFilter._();

  /// Minimum number of samples required to apply the filter.
  /// Matches the Python backend constant (_MIN_FILTER_SAMPLES = 13).
  static const int minSamples = 13;

  // ---------------------------------------------------------------------------
  // Coefficient computation
  // ---------------------------------------------------------------------------

  /// Compute 2nd-order Butterworth LPF (b, a) coefficients.
  ///
  /// [cutoffHz] — 3 dB cutoff frequency in Hz.
  /// [sampleRateHz] — sample rate in Hz.
  ///
  /// Returns a record ({b, a}) each of length 3.
  static ({Float64List b, Float64List a}) butter(
    double cutoffHz,
    double sampleRateHz,
  ) {
    assert(cutoffHz > 0 && cutoffHz < sampleRateHz / 2,
        'cutoffHz must be in (0, sampleRateHz/2)');

    // Bilinear transform prewarped prototype frequency.
    final k = math.tan(math.pi * cutoffHz / sampleRateHz);
    final k2 = k * k;
    final sqrt2k = math.sqrt2 * k;
    final norm = 1.0 / (1.0 + sqrt2k + k2);

    final b = Float64List(3);
    b[0] = k2 * norm;
    b[1] = 2.0 * k2 * norm;
    b[2] = k2 * norm;

    final a = Float64List(3);
    a[0] = 1.0;
    a[1] = 2.0 * (k2 - 1.0) * norm;
    a[2] = (1.0 - sqrt2k + k2) * norm;

    return (b: b, a: a);
  }

  // ---------------------------------------------------------------------------
  // Zero-phase filtering
  // ---------------------------------------------------------------------------

  /// Zero-phase IIR filter (forward + backward pass with odd-reflection padding).
  ///
  /// Returns [signal] unchanged as [Float64List] if it is shorter than
  /// [minSamples], matching Python's _MIN_FILTER_SAMPLES guard.
  ///
  /// [signal] — input samples.
  /// [b], [a] — filter coefficients from [butter].
  static Float64List filtfilt(
    List<double> signal,
    Float64List b,
    Float64List a,
  ) {
    final n = signal.length;
    if (n < minSamples) {
      return Float64List.fromList(signal);
    }

    // Pad length: 3 × max(len(b), len(a)) matching scipy default.
    final int padLen = 3 * math.max(b.length, a.length); // = 9 for order-2

    if (n <= padLen) {
      // Signal too short to pad safely — return as-is.
      return Float64List.fromList(signal);
    }

    // 1. Odd-reflection padding
    final padded = _padOdd(signal, padLen);

    // 2. Forward pass
    final forward = _applyIir(padded, b, a);

    // 3. Reverse
    final reversed = _reverse(forward);

    // 4. Backward pass (= forward pass on reversed signal)
    final backward = _applyIir(reversed, b, a);

    // 5. Reverse back
    final result = _reverse(backward);

    // 6. Extract central portion (remove padding)
    return result.buffer.asFloat64List(padLen * Float64List.bytesPerElement, n);
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Direct Form II Transposed IIR filter implementation.
  ///
  /// Numerically stable for 2nd-order filters. Processes [x] using
  /// coefficients [b] (numerator) and [a] (denominator, a[0] == 1).
  static Float64List _applyIir(Float64List x, Float64List b, Float64List a) {
    final n = x.length;
    final y = Float64List(n);

    final b0 = b[0], b1 = b[1], b2 = b[2];
    final a1 = a[1], a2 = a[2];

    // Delay line state
    var z0 = 0.0;
    var z1 = 0.0;

    for (int i = 0; i < n; i++) {
      final xi = x[i];
      final yi = b0 * xi + z0;
      z0 = b1 * xi - a1 * yi + z1;
      z1 = b2 * xi - a2 * yi;
      y[i] = yi;
    }
    return y;
  }

  /// Create odd-reflection padding at both ends of [signal].
  ///
  /// Left:  2·signal[0] - signal[padLen], …, 2·signal[0] - signal[1]
  /// Right: 2·signal[n-1] - signal[n-2], …, 2·signal[n-1] - signal[n-1-padLen]
  ///
  /// This matches scipy's default padtype='odd'.
  static Float64List _padOdd(List<double> signal, int padLen) {
    final n = signal.length;
    final total = padLen + n + padLen;
    final padded = Float64List(total);

    // Left pad
    for (int i = 0; i < padLen; i++) {
      padded[i] = 2.0 * signal[0] - signal[padLen - i];
    }

    // Signal
    for (int i = 0; i < n; i++) {
      padded[padLen + i] = signal[i];
    }

    // Right pad
    for (int i = 0; i < padLen; i++) {
      padded[padLen + n + i] = 2.0 * signal[n - 1] - signal[n - 2 - i];
    }

    return padded;
  }

  /// Reverse a [Float64List] into a new [Float64List].
  static Float64List _reverse(Float64List x) {
    final n = x.length;
    final r = Float64List(n);
    for (int i = 0; i < n; i++) {
      r[i] = x[n - 1 - i];
    }
    return r;
  }
}
