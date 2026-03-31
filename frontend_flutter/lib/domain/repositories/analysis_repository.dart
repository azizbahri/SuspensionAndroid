import '../../core/error/result.dart';
import '../entities/analysis_result.dart';
import '../entities/bike_profile.dart';
import '../entities/session.dart';
import '../../data/processing/calibration_fitter.dart';

/// Abstract contract for analysis operations and result persistence.
abstract interface class AnalysisRepository {
  /// Run the full signal processing pipeline on [session]'s data.
  Future<Result<AnalysisResult>> analyzeSession(Session session, BikeProfile bike);

  /// Retrieve a stored result without re-running the pipeline.
  Future<Result<AnalysisResult>> getResult(String sessionId);

  /// Persist an [AnalysisResult] to disk.
  Future<Result<void>> saveResult(AnalysisResult result);

  /// Fit front fork linear calibration.
  Future<Result<FrontCalibrationResult>> calibrateFront({
    required List<double> strokesMm,
    required List<double> voltagesV,
  });

  /// Fit rear linkage quadratic calibration.
  Future<Result<RearCalibrationResult>> calibrateRear({
    required List<double> shockStrokesMm,
    required List<double> wheelTravelsMm,
  });

  /// Compare 2–3 analyzed sessions side-by-side.
  Future<Result<CompareResponse>> compareSessions({
    required List<String> sessionIds,
  });
}

/// Side-by-side comparison result.
class CompareResponse {
  const CompareResponse({required this.sessions});
  final List<SessionCompareEntry> sessions;
}

class SessionCompareEntry {
  const SessionCompareEntry({
    required this.sessionId,
    required this.sessionName,
    required this.result,
  });
  final String sessionId;
  final String sessionName;
  final AnalysisResult result;
}
