import 'dart:typed_data';

import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/bike_profile.dart';
import '../../domain/entities/column_map.dart';
import '../hardware/daq_frame.dart';
import 'displacement_processor.dart';
import 'histogram_builder.dart';
import 'pitch_processor.dart';
import 'velocity_processor.dart';
import '../advisor/diagnostic_advisor.dart';

/// Orchestrates the full signal-processing pipeline on a list of [DaqFrame]s.
///
/// Port of backend/app/processing/pipeline.py — process_session()
///
/// Steps:
///   1. Extract raw ADC channels from [DaqFrame] list
///   2. ADC counts → voltage
///   3. Front: voltage → stroke → wheel travel
///      Rear:  voltage → shock stroke → wheel travel (linkage polynomial)
///   4. Filter displacement (Butterworth 20 Hz LPF)
///   5. Compute velocities (wheel or shaft, per [velocityQuantity])
///   6. Compute pitch via complementary filter
///   7. Build histograms
///   8. Run diagnostic advisor
///   9. Return [AnalysisResult]
class SessionPipeline {
  SessionPipeline._();

  /// Process [frames] through the full pipeline and return an [AnalysisResult].
  ///
  /// [bike] — calibration + filter parameters.
  /// [columnMap] — channel inversion flags (column name mapping not needed
  ///   since [DaqFrame] already has typed fields; inversion is still applied).
  /// [velocityQuantity] — [VelocityQuantity.wheel] or [VelocityQuantity.shaft].
  static AnalysisResult process(
    List<DaqFrame> frames,
    BikeProfile bike, {
    ColumnMap columnMap = const ColumnMap(),
    VelocityQuantity velocityQuantity = VelocityQuantity.shaft,
  }) {
    final n = frames.length;
    if (n == 0) {
      throw ArgumentError('frames must not be empty');
    }

    // -------------------------------------------------------------------------
    // 1. Extract time axis
    // -------------------------------------------------------------------------
    final dt = 1.0 / bike.fsHz;
    final t = Float64List(n);
    if (frames.first.timeS != null) {
      final t0 = frames.first.timeS!;
      for (int i = 0; i < n; i++) {
        t[i] = (frames[i].timeS ?? t0 + i * dt) - t0;
      }
    } else {
      for (int i = 0; i < n; i++) {
        t[i] = i * dt;
      }
    }

    // -------------------------------------------------------------------------
    // 2. Extract raw ADC channels
    // -------------------------------------------------------------------------
    final frontRaw = <int>[];
    final rearRaw = <int>[];
    final gyroYRaw = <int>[];
    final accelXRaw = <int>[];
    final accelYRaw = <int>[];
    final accelZRaw = <int>[];

    // Inversion sign
    final fSign = columnMap.invertFront ? -1 : 1;
    final rSign = columnMap.invertRear ? -1 : 1;

    for (final f in frames) {
      frontRaw.add(f.frontRaw * fSign);
      rearRaw.add(f.rearRaw * rSign);
      gyroYRaw.add(f.gyroYRaw);
      accelXRaw.add(f.accelXRaw);
      accelYRaw.add(f.accelYRaw);
      accelZRaw.add(f.accelZRaw);
    }

    // -------------------------------------------------------------------------
    // 3. ADC → Voltage → Displacement
    // -------------------------------------------------------------------------
    final vFront = DisplacementProcessor.adcToVoltage(
      frontRaw,
      adcBits: bike.adcBits,
      vRef: bike.vRef,
    );
    final vRear = DisplacementProcessor.adcToVoltage(
      rearRaw,
      adcBits: bike.adcBits,
      vRef: bike.vRef,
    );

    final sFront = DisplacementProcessor.frontStroke(
      vFront,
      v0Front: bike.v0Front,
      cFront: bike.cFront,
    );
    final wFront = DisplacementProcessor.frontTravel(
      sFront,
      forkAngleDeg: bike.forkAngleDeg,
    );

    final sRear = DisplacementProcessor.rearStroke(
      vRear,
      v0Rear: bike.v0Rear,
      cRear: bike.cRear,
    );
    final wRear = DisplacementProcessor.rearTravel(
      sRear,
      a: bike.linkageA,
      b: bike.linkageB,
      c: bike.linkageC,
    );

    // -------------------------------------------------------------------------
    // 4. Filter displacement
    // -------------------------------------------------------------------------
    final wFrontF = VelocityProcessor.filterDisplacement(
      wFront,
      fsHz: bike.fsHz,
      cutoffHz: bike.lpfCutoffDispHz,
    );
    final wRearF = VelocityProcessor.filterDisplacement(
      wRear,
      fsHz: bike.fsHz,
      cutoffHz: bike.lpfCutoffDispHz,
    );

    // -------------------------------------------------------------------------
    // 5. Velocity
    // -------------------------------------------------------------------------
    late Float64List vFrontHist;
    late Float64List vRearHist;

    if (velocityQuantity == VelocityQuantity.wheel) {
      vFrontHist = VelocityProcessor.wheelVelocity(wFrontF, fsHz: bike.fsHz);
      vRearHist = VelocityProcessor.wheelVelocity(wRearF, fsHz: bike.fsHz);
    } else {
      // shaft
      final vFrontWheel =
          VelocityProcessor.wheelVelocity(wFrontF, fsHz: bike.fsHz);
      vFrontHist = VelocityProcessor.shaftVelocityFront(
        vFrontWheel,
        forkAngleDeg: bike.forkAngleDeg,
      );
      vRearHist = VelocityProcessor.shaftVelocityRear(
        sRear,
        fsHz: bike.fsHz,
        cutoffHz: bike.lpfCutoffDispHz,
      );
    }

    // -------------------------------------------------------------------------
    // 6. Travel percent
    // -------------------------------------------------------------------------
    final pFront = DisplacementProcessor.travelPercent(
      wFrontF,
      wMaxMm: bike.wMaxFrontMm,
    );
    final pRear = DisplacementProcessor.travelPercent(
      wRearF,
      wMaxMm: bike.wMaxRearMm,
    );

    // -------------------------------------------------------------------------
    // 7. Pitch (complementary filter)
    // -------------------------------------------------------------------------
    final omegaRaw = PitchProcessor.gyroToDegS(
      gyroYRaw,
      sensitivity: bike.gyroSensitivity,
    );
    final (:corrected, bias: _) = PitchProcessor.removeBias(
      omegaRaw,
      stationarySamples: bike.stationarySamples,
    );

    final omegaF = PitchProcessor.filterGyro(
      corrected,
      fsHz: bike.fsHz,
      cutoffHz: bike.lpfCutoffGyroHz,
    );

    final accelSens = bike.accelSensitivity;
    final axG = Float64List.fromList(
      accelXRaw.map((v) => v / accelSens).toList(),
    );
    final ayG = Float64List.fromList(
      accelYRaw.map((v) => v / accelSens).toList(),
    );
    // Default az to 1 g if all zeros (missing channel)
    final azRawSafe = accelZRaw.every((v) => v == 0)
        ? List.filled(n, accelSens.round())
        : accelZRaw;
    final azG = Float64List.fromList(
      azRawSafe.map((v) => v / accelSens).toList(),
    );

    final phiAcc = PitchProcessor.accelPitchDeg(axG, ayG, azG);
    final phi = PitchProcessor.complementaryFilterPitch(
      omegaF,
      phiAcc,
      fsHz: bike.fsHz,
      alpha: bike.complementaryAlpha,
    );

    final accelXG = PitchProcessor.longitudinalAccelG(
      accelXRaw,
      accelSensitivity: accelSens,
    );

    // -------------------------------------------------------------------------
    // 8. Histograms
    // -------------------------------------------------------------------------
    final frontTravelHist =
        HistogramBuilder.buildTravelHistogram(pFront, lsThreshold: 80.0);
    final rearTravelHist =
        HistogramBuilder.buildTravelHistogram(pRear, lsThreshold: 80.0);
    final frontVelHist = HistogramBuilder.buildVelocityHistogram(
      vFrontHist,
      lsThreshold: bike.lsThresholdMmS,
    );
    final rearVelHist = HistogramBuilder.buildVelocityHistogram(
      vRearHist,
      lsThreshold: bike.lsThresholdMmS,
    );

    final pitch = PitchTrace(
      timeS: List<double>.from(t),
      pitchDeg: List<double>.from(phi),
      accelXG: List<double>.from(accelXG),
    );

    // -------------------------------------------------------------------------
    // 9. Diagnostic advisor
    // -------------------------------------------------------------------------
    final result = AnalysisResult(
      sessionId: '',
      frontTravel: frontTravelHist,
      rearTravel: rearTravelHist,
      frontVelocity: frontVelHist,
      rearVelocity: rearVelHist,
      pitch: pitch,
      diagnostics: [],
      durationS: t.isNotEmpty ? t.last : 0.0,
      sampleCount: n,
    );

    final diagnostics = DiagnosticAdvisor.run(result, bike);
    return result.copyWith(diagnostics: diagnostics);
  }
}

/// Which velocity quantity to compute.
enum VelocityQuantity { wheel, shaft }
