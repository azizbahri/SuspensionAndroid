import '../../core/error/result.dart';
import '../../data/hardware/csv_data_source.dart';
import '../../data/hardware/data_source.dart';
import '../../data/local/bike_storage.dart';
import '../../data/local/session_storage.dart';
import '../../data/processing/calibration_fitter.dart';
import '../../data/processing/session_pipeline.dart';
import '../../data/simulator/simulator_source.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/bike_profile.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/analysis_repository.dart';

/// Concrete implementation of [AnalysisRepository].
///
/// Orchestrates:
///   - Data acquisition from the session's [DataSource]
///   - Signal processing via [SessionPipeline]
///   - Calibration fitting via [CalibrationFitter]
///   - Result persistence via [SessionStorage]
class AnalysisRepositoryImpl implements AnalysisRepository {
  AnalysisRepositoryImpl({
    required SessionStorage sessionStorage,
    required BikeStorage bikeStorage,
  })  : _sessionStorage = sessionStorage,
        _bikeStorage = bikeStorage;

  final SessionStorage _sessionStorage;
  final BikeStorage _bikeStorage;

  @override
  Future<Result<AnalysisResult>> analyzeSession(
      Session session, BikeProfile bike) async {
    try {
      // 1. Obtain the data source for this session
      final DataSource source = _buildSource(session, bike);

      // 2. Acquire frames
      final frames = await source.acquire();
      if (frames.isEmpty) {
        return const Failure(
            ProcessingException('Data source returned no frames'));
      }

      // 3. Run pipeline
      final result = SessionPipeline.process(
        frames,
        bike,
        columnMap: session.columnMap,
        velocityQuantity: session.velocityQuantity,
      );

      // 4. Tag with session ID and save
      final tagged = result.copyWith(sessionId: session.id);
      await _sessionStorage.saveResult(tagged);

      // 5. Mark session as analyzed
      final updated = session.copyWith(analyzed: true);
      await _sessionStorage.saveSession(updated);

      return Success(tagged);
    } on HardwareException catch (e) {
      return Failure(e);
    } on SimulatorException catch (e) {
      return Failure(e);
    } catch (e) {
      return Failure(ProcessingException('Analysis failed: $e'));
    }
  }

  @override
  Future<Result<AnalysisResult>> getResult(String sessionId) =>
      _sessionStorage.loadResult(sessionId);

  @override
  Future<Result<void>> saveResult(AnalysisResult result) =>
      _sessionStorage.saveResult(result);

  @override
  Future<Result<FrontCalibrationResult>> calibrateFront({
    required List<double> strokesMm,
    required List<double> voltagesV,
  }) async {
    try {
      final result = CalibrationFitter.fitFrontLinear(
        strokesMm: strokesMm,
        voltagesV: voltagesV,
      );
      return Success(result);
    } catch (e) {
      return Failure(ProcessingException('Front calibration failed: $e'));
    }
  }

  @override
  Future<Result<RearCalibrationResult>> calibrateRear({
    required List<double> shockStrokesMm,
    required List<double> wheelTravelsMm,
  }) async {
    try {
      final result = CalibrationFitter.fitRearLinkage(
        shockStrokesMm: shockStrokesMm,
        wheelTravelsMm: wheelTravelsMm,
      );
      return Success(result);
    } catch (e) {
      return Failure(ProcessingException('Rear calibration failed: $e'));
    }
  }

  @override
  Future<Result<CompareResponse>> compareSessions({
    required List<String> sessionIds,
  }) async {
    final entries = <SessionCompareEntry>[];
    for (final id in sessionIds) {
      final sessionResult = await _sessionStorage.loadSession(id);
      if (sessionResult is Failure) {
        return Failure(
            NotFoundException("Session '$id' not found for comparison"));
      }
      final session = (sessionResult as Success<Session>).data;

      final resultResult = await _sessionStorage.loadResult(id);
      if (resultResult is Failure) {
        return Failure(NotFoundException(
            "Session '${session.name}' has not been analyzed yet"));
      }
      entries.add(SessionCompareEntry(
        sessionId: id,
        sessionName: session.name,
        result: (resultResult as Success<AnalysisResult>).data,
      ));
    }
    return Success(CompareResponse(sessions: entries));
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  DataSource _buildSource(Session session, BikeProfile bike) {
    switch (session.dataSourceType) {
      case DataSourceType.simulator:
        if (session.simulatorConfig == null) {
          throw const SimulatorException('No simulator config in session');
        }
        return SimulatorSource(
          config: session.simulatorConfig!,
          bike: bike,
        );
      case DataSourceType.csvFile:
        if (session.csvPath == null) {
          throw const FileException('No CSV path in session');
        }
        return CsvDataSource(
          csvPath: session.csvPath!,
          columnMap: session.columnMap,
        );
      case DataSourceType.usbOtg:
      case DataSourceType.ble:
        throw const HardwareException(
            'Hardware data source not yet implemented');
    }
  }
}
