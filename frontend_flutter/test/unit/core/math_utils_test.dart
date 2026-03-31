import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/utils/math_utils.dart';

void main() {
  group('MathUtils.polyfit1', () {
    test('perfect linear data → exact coefficients', () {
      final x = [0.0, 1.0, 2.0, 3.0, 4.0];
      final y = [1.0, 3.0, 5.0, 7.0, 9.0]; // y = 2x + 1
      final coeffs = MathUtils.polyfit1(x, y);
      expect(coeffs[0], closeTo(2.0, 1e-10)); // slope
      expect(coeffs[1], closeTo(1.0, 1e-10)); // intercept
    });

    test('horizontal line → slope = 0', () {
      final x = [0.0, 1.0, 2.0];
      final y = [5.0, 5.0, 5.0];
      final coeffs = MathUtils.polyfit1(x, y);
      expect(coeffs[0], closeTo(0.0, 1e-10));
      expect(coeffs[1], closeTo(5.0, 1e-10));
    });

    test('throws for fewer than 2 points', () {
      expect(() => MathUtils.polyfit1([1.0], [1.0]), throwsArgumentError);
    });
  });

  group('MathUtils.polyfit2', () {
    test('perfect quadratic data → exact coefficients', () {
      // y = -0.015x² + 4.2x + 0
      final x = [0.0, 10.0, 20.0, 30.0, 40.0, 50.0];
      final y = x.map((xi) => -0.015 * xi * xi + 4.2 * xi).toList();
      final coeffs = MathUtils.polyfit2(x, y);
      expect(coeffs[0], closeTo(-0.015, 1e-8));
      expect(coeffs[1], closeTo(4.2, 1e-8));
      expect(coeffs[2], closeTo(0.0, 1e-8));
    });

    test('throws for fewer than 3 points', () {
      expect(() => MathUtils.polyfit2([0.0, 1.0], [0.0, 1.0]),
          throwsArgumentError);
    });
  });

  group('MathUtils.standardDeviation', () {
    test('all-same values → std = 0', () {
      expect(MathUtils.standardDeviation([3.0, 3.0, 3.0]), 0.0);
    });

    test('known std', () {
      // [2, 4, 4, 4, 5, 5, 7, 9] → std = 2.0
      final data = [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      expect(MathUtils.standardDeviation(data), closeTo(2.0, 1e-6));
    });
  });

  group('MathUtils.histogram', () {
    test('bins sum to total count', () {
      final data = List.generate(100, (i) => i.toDouble());
      final edges = [0.0, 25.0, 50.0, 75.0, 100.0];
      final counts = MathUtils.histogram(data, edges);
      expect(counts.reduce((a, b) => a + b), 100);
    });

    test('uniform data distributed evenly', () {
      final data = [5.0, 15.0, 25.0, 35.0, 45.0];
      final edges = [0.0, 10.0, 20.0, 30.0, 40.0, 50.0];
      final counts = MathUtils.histogram(data, edges);
      expect(counts, [1, 1, 1, 1, 1]);
    });

    test('NaN values are ignored', () {
      final data = [5.0, double.nan, 15.0];
      final edges = [0.0, 10.0, 20.0];
      final counts = MathUtils.histogram(data, edges);
      expect(counts.reduce((a, b) => a + b), 2);
    });

    test('travel histogram: 10 bins from 0 to 100', () {
      final edges = List.generate(11, (i) => i * 10.0);
      final data = [5.0, 15.0, 25.0, 35.0, 45.0, 55.0, 65.0, 75.0, 85.0, 95.0];
      final counts = MathUtils.histogram(data, edges);
      expect(counts.length, 10);
      expect(counts.every((c) => c == 1), isTrue);
    });
  });

  group('MathUtils.rmse', () {
    test('identical arrays → 0', () {
      expect(MathUtils.rmse([1.0, 2.0, 3.0], [1.0, 2.0, 3.0]), 0.0);
    });

    test('known RMSE', () {
      expect(MathUtils.rmse([0.0, 0.0], [1.0, 1.0]), closeTo(1.0, 1e-10));
    });
  });
}
