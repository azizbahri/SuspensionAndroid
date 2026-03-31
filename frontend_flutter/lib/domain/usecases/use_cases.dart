// Use cases — single-responsibility callable classes.
// Each use case wraps one business operation and performs validation
// before delegating to a repository.

import '../../core/error/result.dart';
import '../entities/bike_profile.dart';
import '../entities/session.dart';
import '../entities/analysis_result.dart';
import '../repositories/bike_repository.dart';
import '../repositories/session_repository.dart';
import '../repositories/analysis_repository.dart';
import '../../data/processing/calibration_fitter.dart';

// ---------------------------------------------------------------------------
// Bike use cases
// ---------------------------------------------------------------------------

final class GetBikesUseCase {
  const GetBikesUseCase(this._repo);
  final BikeRepository _repo;
  Future<Result<List<BikeProfile>>> call() => _repo.getBikes();
}

final class CreateBikeUseCase {
  const CreateBikeUseCase(this._repo);
  final BikeRepository _repo;

  Future<Result<BikeProfile>> call(BikeProfile bike) {
    if (bike.name.trim().isEmpty) {
      return Future.value(const Failure(ValidationException('Bike name must not be empty')));
    }
    if (bike.slug.trim().isEmpty) {
      return Future.value(const Failure(ValidationException('Bike slug must not be empty')));
    }
    return _repo.createBike(bike);
  }
}

final class UpdateBikeUseCase {
  const UpdateBikeUseCase(this._repo);
  final BikeRepository _repo;
  Future<Result<BikeProfile>> call(String slug, BikeProfile bike) =>
      _repo.updateBike(slug, bike);
}

final class DeleteBikeUseCase {
  const DeleteBikeUseCase(this._repo);
  final BikeRepository _repo;
  Future<Result<void>> call(String slug) => _repo.deleteBike(slug);
}

// ---------------------------------------------------------------------------
// Session use cases
// ---------------------------------------------------------------------------

final class GetSessionsUseCase {
  const GetSessionsUseCase(this._repo);
  final SessionRepository _repo;
  Future<Result<List<Session>>> call() => _repo.getSessions();
}

final class CreateSessionUseCase {
  const CreateSessionUseCase(this._repo);
  final SessionRepository _repo;

  Future<Result<Session>> call(Session session) {
    if (session.name.trim().isEmpty) {
      return Future.value(
          const Failure(ValidationException('Session name must not be empty')));
    }
    if (session.bikeSlug.trim().isEmpty) {
      return Future.value(
          const Failure(ValidationException('A bike profile must be selected')));
    }
    return _repo.createSession(session);
  }
}

final class DeleteSessionUseCase {
  const DeleteSessionUseCase(this._repo);
  final SessionRepository _repo;
  Future<Result<void>> call(String id) => _repo.deleteSession(id);
}

// ---------------------------------------------------------------------------
// Analysis use cases
// ---------------------------------------------------------------------------

final class AnalyzeSessionUseCase {
  const AnalyzeSessionUseCase(this._analysisRepo, this._bikeRepo);
  final AnalysisRepository _analysisRepo;
  final BikeRepository _bikeRepo;

  Future<Result<AnalysisResult>> call(Session session) async {
    // Load bike profile
    final bikeResult = await _bikeRepo.getBike(session.bikeSlug);
    if (bikeResult is Failure) return Failure((bikeResult as Failure).exception);
    final bike = (bikeResult as Success<BikeProfile>).data;

    // Run pipeline
    return _analysisRepo.analyzeSession(session, bike);
  }
}

final class GetAnalysisResultUseCase {
  const GetAnalysisResultUseCase(this._repo);
  final AnalysisRepository _repo;
  Future<Result<AnalysisResult>> call(String sessionId) =>
      _repo.getResult(sessionId);
}

final class CalibrateFrontUseCase {
  const CalibrateFrontUseCase(this._repo);
  final AnalysisRepository _repo;

  Future<Result<FrontCalibrationResult>> call({
    required List<double> strokesMm,
    required List<double> voltagesV,
  }) {
    if (strokesMm.length < 2 || voltagesV.length < 2) {
      return Future.value(const Failure(
          ValidationException('Need at least 2 calibration points')));
    }
    if (strokesMm.length != voltagesV.length) {
      return Future.value(const Failure(
          ValidationException('Stroke and voltage arrays must be the same length')));
    }
    return _repo.calibrateFront(strokesMm: strokesMm, voltagesV: voltagesV);
  }
}

final class CalibrateRearUseCase {
  const CalibrateRearUseCase(this._repo);
  final AnalysisRepository _repo;

  Future<Result<RearCalibrationResult>> call({
    required List<double> shockStrokesMm,
    required List<double> wheelTravelsMm,
  }) {
    if (shockStrokesMm.length < 3 || wheelTravelsMm.length < 3) {
      return Future.value(const Failure(
          ValidationException('Need at least 3 calibration points')));
    }
    if (shockStrokesMm.length != wheelTravelsMm.length) {
      return Future.value(const Failure(
          ValidationException('Arrays must be the same length')));
    }
    return _repo.calibrateRear(
        shockStrokesMm: shockStrokesMm, wheelTravelsMm: wheelTravelsMm);
  }
}

final class CompareSessionsUseCase {
  const CompareSessionsUseCase(this._repo);
  final AnalysisRepository _repo;

  Future<Result<CompareResponse>> call(List<String> sessionIds) {
    if (sessionIds.length < 2) {
      return Future.value(
          const Failure(ValidationException('Select at least 2 sessions to compare')));
    }
    if (sessionIds.length > 3) {
      return Future.value(
          const Failure(ValidationException('Maximum 3 sessions can be compared')));
    }
    return _repo.compareSessions(sessionIds: sessionIds);
  }
}
