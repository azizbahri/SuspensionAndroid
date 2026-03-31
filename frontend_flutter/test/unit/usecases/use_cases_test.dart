import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/error/result.dart';
import '../../../lib/domain/entities/analysis_result.dart';
import '../../../lib/domain/entities/bike_profile.dart';
import '../../../lib/domain/entities/session.dart';
import '../../../lib/domain/repositories/analysis_repository.dart';
import '../../../lib/domain/repositories/bike_repository.dart';
import '../../../lib/domain/usecases/use_cases.dart';
import '../../../lib/data/processing/calibration_fitter.dart';

void main() {
  group('CompareSessionsUseCase — validation', () {
    // Use a stub repository that always succeeds
    final repo = _StubAnalysisRepository();
    final useCase = CompareSessionsUseCase(repo);

    test('0 sessions → ValidationException', () async {
      final result = await useCase([]);
      expect(result, isA<Failure>());
      expect((result as Failure).exception, isA<ValidationException>());
    });

    test('1 session → ValidationException', () async {
      final result = await useCase(['id-1']);
      expect(result, isA<Failure>());
      expect((result as Failure).exception, isA<ValidationException>());
    });

    test('4 sessions → ValidationException', () async {
      final result = await useCase(['a', 'b', 'c', 'd']);
      expect(result, isA<Failure>());
    });

    test('2 sessions → calls repository', () async {
      await useCase(['id-1', 'id-2']);
      expect(repo.compareCallCount, 1);
    });

  test('3 sessions → calls repository', () async {
      await useCase(['id-1', 'id-2', 'id-3']);
      expect(repo.compareCallCount, 2);
    });
  });

  group('CalibrateFrontUseCase — validation', () {
    final repo = _StubAnalysisRepository();
    final useCase = CalibrateFrontUseCase(repo);

    test('fewer than 2 points → ValidationException', () async {
      final r = await useCase(strokesMm: [0.0], voltagesV: [0.5]);
      expect(r, isA<Failure>());
      expect((r as Failure).exception, isA<ValidationException>());
    });

    test('mismatched arrays → ValidationException', () async {
      final r = await useCase(
          strokesMm: [0.0, 100.0], voltagesV: [0.5]);
      expect(r, isA<Failure>());
    });

    test('valid 2-point input → calls repository', () async {
      await useCase(strokesMm: [0.0, 100.0], voltagesV: [0.5, 1.5]);
      expect(repo.calibrateFrontCallCount, 1);
    });
  });

  group('CalibrateRearUseCase — validation', () {
    final repo = _StubAnalysisRepository();
    final useCase = CalibrateRearUseCase(repo);

    test('fewer than 3 points → ValidationException', () async {
      final r = await useCase(
          shockStrokesMm: [0.0, 10.0], wheelTravelsMm: [0.0, 40.0]);
      expect(r, isA<Failure>());
    });

    test('valid 3-point input → calls repository', () async {
      await useCase(
          shockStrokesMm: [0.0, 10.0, 20.0],
          wheelTravelsMm: [0.0, 40.0, 90.0]);
      expect(repo.calibrateRearCallCount, 1);
    });
  });

  group('CreateBikeUseCase — validation', () {
    final bikeRepo = _StubBikeRepository();
    final useCase = CreateBikeUseCase(bikeRepo);

    test('empty name → ValidationException', () async {
      final r = await useCase(
          const BikeProfileStub(name: '', slug: 't7'));
      expect(r, isA<Failure>());
    });

    test('empty slug → ValidationException', () async {
      final r = await useCase(
          const BikeProfileStub(name: 'T7', slug: ''));
      expect(r, isA<Failure>());
    });
  });
}

// ---------------------------------------------------------------------------
// Stubs
// ---------------------------------------------------------------------------

class _StubAnalysisRepository implements AnalysisRepository {
  int compareCallCount = 0;
  int calibrateFrontCallCount = 0;
  int calibrateRearCallCount = 0;

  @override
  Future<Result<AnalysisResult>> analyzeSession(
          Session session, BikeProfile bike) async =>
      const Failure(NotFoundException('stub'));

  @override
  Future<Result<AnalysisResult>> getResult(String sessionId) async =>
      const Failure(NotFoundException('stub'));

  @override
  Future<Result<void>> saveResult(AnalysisResult result) async =>
      const Success(null);

  @override
  Future<Result<FrontCalibrationResult>> calibrateFront({
    required List<double> strokesMm,
    required List<double> voltagesV,
  }) async {
    calibrateFrontCallCount++;
    return const Success(
        FrontCalibrationResult(cCal: 42.0, v0: 0.5, rmseMm: 0.0));
  }

  @override
  Future<Result<RearCalibrationResult>> calibrateRear({
    required List<double> shockStrokesMm,
    required List<double> wheelTravelsMm,
  }) async {
    calibrateRearCallCount++;
    return const Success(
        RearCalibrationResult(a: -0.015, b: 4.2, c: 0.0, rmseMm: 0.0));
  }

  @override
  Future<Result<CompareResponse>> compareSessions(
      {required List<String> sessionIds}) async {
    compareCallCount++;
    return const Success(CompareResponse(sessions: []));
  }
}

class _StubBikeRepository implements BikeRepository {
  @override
  Future<Result<List<BikeProfile>>> getBikes() async => const Success([]);

  @override
  Future<Result<BikeProfile>> getBike(String slug) async =>
      const Failure(NotFoundException('stub'));

  @override
  Future<Result<BikeProfile>> createBike(BikeProfile bike) async =>
      Success(bike);

  @override
  Future<Result<BikeProfile>> updateBike(String slug, BikeProfile bike) async =>
      Success(bike);

  @override
  Future<Result<void>> deleteBike(String slug) async =>
      const Success(null);
}

// Minimal BikeProfile substitute for test stubs
class BikeProfileStub extends BikeProfile {
  const BikeProfileStub({required String name, required String slug})
      : super(name: name, slug: slug);
}
