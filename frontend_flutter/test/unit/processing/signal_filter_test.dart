import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../../lib/data/processing/signal_filter.dart';

void main() {
  group('SignalFilter.butter', () {
    test('returns 3 coefficients for b and a', () {
      final (:b, :a) = SignalFilter.butter(20.0, 250.0);
      expect(b.length, 3);
      expect(a.length, 3);
    });

    test('a[0] is always 1', () {
      final (:b, :a) = SignalFilter.butter(10.0, 100.0);
      expect(a[0], 1.0);
    });

    test('DC gain is 1 (sum(b) / (1 + sum(a[1:])) ≈ 1)', () {
      final (:b, :a) = SignalFilter.butter(20.0, 250.0);
      final sumB = b[0] + b[1] + b[2];
      final sumA = 1.0 + a[1] + a[2];
      expect(sumB / sumA, closeTo(1.0, 1e-8));
    });

    test('b[0] == b[2] (symmetric numerator)', () {
      final (:b, :a) = SignalFilter.butter(15.0, 250.0);
      expect(b[0], closeTo(b[2], 1e-12));
    });

    test('specific coefficients for fc=20Hz fs=250Hz (matches scipy reference)', () {
      // Reference values from scipy.signal.butter(2, 20/125.0):
      //   b = [0.04613180, 0.09226360, 0.04613180]
      //   a = [1.0, -1.30728503, 0.49181224]
      final (:b, :a) = SignalFilter.butter(20.0, 250.0);
      expect(b[0], closeTo(0.04613180, 1e-6));
      expect(b[1], closeTo(0.09226360, 1e-6));
      expect(a[1], closeTo(-1.30728503, 1e-6));
      expect(a[2], closeTo(0.49181224, 1e-6));
    });
  });

  group('SignalFilter.filtfilt', () {
    final (:b, :a) = SignalFilter.butter(20.0, 250.0);

    test('returns input unchanged if fewer than minSamples', () {
      const signal = [1.0, 2.0, 3.0, 4.0];
      final out = SignalFilter.filtfilt(signal, b, a);
      expect(out.length, 4);
      expect(out[0], 1.0);
      expect(out[3], 4.0);
    });

    test('output length equals input length', () {
      final signal = List.generate(500, (i) => i.toDouble());
      final out = SignalFilter.filtfilt(signal, b, a);
      expect(out.length, 500);
    });

    test('DC signal passes through unchanged', () {
      final signal = List.filled(200, 5.0);
      final out = SignalFilter.filtfilt(signal, b, a);
      for (final v in out) {
        expect(v, closeTo(5.0, 1e-6));
      }
    });

    test('high-frequency sine is attenuated below 20Hz cutoff', () {
      // 100 Hz sine at 250 Hz sample rate → should be heavily attenuated
      final fs = 250.0;
      final signal = List.generate(
          500, (i) => math.sin(2 * math.pi * 100.0 * i / fs));
      final out = SignalFilter.filtfilt(signal, b, a);
      // Ignore boundary samples where odd-padding edge effects dominate.
      final core = out.skip(50).take(out.length - 100);
      final maxAmp = core.map((v) => v.abs()).reduce(math.max);
      expect(maxAmp, lessThan(0.1));
    });

    test('low-frequency sine passes with near-unity gain', () {
      // 1 Hz sine at 250 Hz sample rate → should pass through (well below 20Hz cutoff)
      const fs = 250.0;
      final signal = List.generate(
          1000, (i) => math.sin(2 * math.pi * 1.0 * i / fs));
      final out = SignalFilter.filtfilt(signal, b, a);
      // Measure amplitude after filter transient (skip first 50 samples)
      final maxAmp =
          out.skip(50).map((v) => v.abs()).reduce(math.max);
      expect(maxAmp, greaterThan(0.9));
    });

    test('zero-phase: symmetric signal has minimum phase distortion', () {
      // A step function should not exhibit pre-ringing (zero-phase)
      final signal = List.generate(200, (i) => i < 100 ? 0.0 : 1.0);
      final out = SignalFilter.filtfilt(signal, b, a);
      // Mid-point should be at ~0.5 due to symmetry
      expect(out[100], closeTo(0.5, 0.15));
    });
  });
}
