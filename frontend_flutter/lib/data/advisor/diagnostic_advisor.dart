import 'dart:typed_data';

import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/bike_profile.dart';

/// Diagnostic rule engine — 7 rules ported from backend/app/advisor/rules.py.
///
/// Each rule is a static method taking ([AnalysisResult], [BikeProfile])
/// and returning a [DiagnosticNote] or null.
/// [run] collects all non-null results.
class DiagnosticAdvisor {
  DiagnosticAdvisor._();

  static List<DiagnosticNote> run(AnalysisResult result, BikeProfile bike) {
    final rules = [
      _deepTravelTail,
      _travelCenterShiftedRight,
      _travelCenterShiftedLeft,
      _harshHsCompression,
      _brakeDive,
      _compressionAsymmetry,
      _reboundKickback,
    ];

    final notes = <DiagnosticNote>[];
    for (final rule in rules) {
      try {
        final note = rule(result, bike);
        if (note != null) notes.add(note);
      } catch (_) {
        // Never let an advisor rule crash the pipeline.
      }
    }
    return notes;
  }

  // ---------------------------------------------------------------------------
  // Rules (private static functions)
  // ---------------------------------------------------------------------------

  static DiagnosticNote? _deepTravelTail(
      AnalysisResult r, BikeProfile bike) {
    for (final hist in [r.frontTravel, r.rearTravel]) {
      if (hist.pctAbove80 > 10.0) {
        return DiagnosticNote(
          ruleId: 'deep_travel_tail',
          severity: DiagnosticSeverity.warning,
          title: 'Excessive deep-stroke usage',
          message:
              '${hist.pctAbove80.toStringAsFixed(1)}% of ride time above 80% travel. '
              'The spring may be too soft or the bike is under-preloaded.',
          action: 'If histogram center is correct (~30–40%), fit a stiffer spring. '
              'If the whole distribution is shifted right, increase preload first.',
        );
      }
    }
    return null;
  }

  static DiagnosticNote? _travelCenterShiftedRight(
      AnalysisResult r, BikeProfile bike) {
    for (final hist in [r.frontTravel, r.rearTravel]) {
      if (hist.peakCenterPct > 50.0) {
        return DiagnosticNote(
          ruleId: 'travel_center_shifted_right',
          severity: DiagnosticSeverity.warning,
          title: 'Ride height too low',
          message:
              'Histogram peak at ${hist.peakCenterPct.toStringAsFixed(0)}% travel '
              '(target: 30–40%). Suspension operating too deep in stroke.',
          action: 'Increase preload to raise the static equilibrium point.',
        );
      }
    }
    return null;
  }

  static DiagnosticNote? _travelCenterShiftedLeft(
      AnalysisResult r, BikeProfile bike) {
    for (final hist in [r.frontTravel, r.rearTravel]) {
      if (hist.peakCenterPct < 20.0) {
        return DiagnosticNote(
          ruleId: 'travel_center_shifted_left',
          severity: DiagnosticSeverity.info,
          title: 'Ride height too high',
          message:
              'Histogram peak at ${hist.peakCenterPct.toStringAsFixed(0)}% travel. '
              'Bike is not using enough of the available stroke.',
          action: 'Reduce preload. If problem persists, spring may be too stiff.',
        );
      }
    }
    return null;
  }

  static DiagnosticNote? _harshHsCompression(
      AnalysisResult r, BikeProfile bike) {
    for (final pair in [
      ('Front', r.frontVelocity),
      ('Rear', r.rearVelocity),
    ]) {
      final label = pair.$1;
      final hist = pair.$2;
      if (hist.hsCompressionPct > 20.0) {
        return DiagnosticNote(
          ruleId: 'harsh_hs_compression',
          severity: DiagnosticSeverity.critical,
          title: '$label: harsh high-speed compression',
          message:
              '${hist.hsCompressionPct.toStringAsFixed(1)}% of ride time in HS compression '
              '(>${bike.lsThresholdMmS.toStringAsFixed(0)} mm/s). Damper may be hydraulically locking.',
          action:
              'Reduce (open) high-speed compression damping. '
              'If no external adjuster, consider lighter oil or shim re-valve.',
        );
      }
    }
    return null;
  }

  static DiagnosticNote? _brakeDive(AnalysisResult r, BikeProfile bike) {
    final pitch = r.pitch.pitchDeg;
    final accel = r.pitch.accelXG;
    if (pitch.isEmpty || accel.isEmpty) return null;

    // Check if any braking event (ax < -0.5 g) exists
    bool anyBraking = false;
    double maxNoseDown = 0.0;
    for (int i = 0; i < pitch.length; i++) {
      if (accel[i] < -0.5) {
        anyBraking = true;
        if (pitch[i] < maxNoseDown) maxNoseDown = pitch[i];
      }
    }
    if (!anyBraking || maxNoseDown > -15.0) return null;

    // Check front velocity — must be LS-dominated
    final centers = r.frontVelocity.centersMmS;
    final timePct = r.frontVelocity.timePct;
    double lsComp = 0, hsComp = 0;
    for (int i = 0; i < centers.length; i++) {
      if (centers[i] < 0) {
        if (centers[i].abs() <= bike.lsThresholdMmS) {
          lsComp += timePct[i];
        } else {
          hsComp += timePct[i];
        }
      }
    }

    if (lsComp > hsComp) {
      return DiagnosticNote(
        ruleId: 'brake_dive',
        severity: DiagnosticSeverity.warning,
        title: 'Excessive brake dive',
        message:
            'Pitch reached ${maxNoseDown.toStringAsFixed(1)}° during braking '
            '(threshold: −15°). Fork velocity is primarily in the low-speed zone.',
        action:
            'Increase low-speed compression damping by 2–3 clicks to slow weight transfer.',
      );
    }
    return null;
  }

  static DiagnosticNote? _compressionAsymmetry(
      AnalysisResult r, BikeProfile bike) {
    for (final pair in [
      ('Front', r.frontVelocity),
      ('Rear', r.rearVelocity),
    ]) {
      final label = pair.$1;
      final hist = pair.$2;
      if (hist.reboundAreaPct > 0 &&
          hist.compressionAreaPct > hist.reboundAreaPct * 1.5) {
        final ratio =
            hist.compressionAreaPct / hist.reboundAreaPct.clamp(0.1, double.infinity);
        return DiagnosticNote(
          ruleId: 'compression_asymmetry',
          severity: DiagnosticSeverity.warning,
          title: '$label: suspension packing (slow rebound)',
          message:
              'Compression (${hist.compressionAreaPct.toStringAsFixed(1)}%) is '
              '${ratio.toStringAsFixed(1)}× the rebound (${hist.reboundAreaPct.toStringAsFixed(1)}%). '
              'Suspension may not recover between bumps.',
          action:
              'Reduce (open) rebound damping so the spring returns the wheel faster.',
        );
      }
    }
    return null;
  }

  static DiagnosticNote? _reboundKickback(
      AnalysisResult r, BikeProfile bike) {
    for (final pair in [
      ('Front', r.frontVelocity),
      ('Rear', r.rearVelocity),
    ]) {
      final label = pair.$1;
      final hist = pair.$2;
      if (hist.compressionAreaPct > 0 &&
          hist.reboundAreaPct > hist.compressionAreaPct * 1.5) {
        return DiagnosticNote(
          ruleId: 'rebound_kickback',
          severity: DiagnosticSeverity.warning,
          title: '$label: rebound kickback / pogo',
          message:
              'Rebound (${hist.reboundAreaPct.toStringAsFixed(1)}%) significantly larger than '
              'compression (${hist.compressionAreaPct.toStringAsFixed(1)}%). '
              'Suspension returning energy too violently.',
          action: 'Increase (close) rebound damping to control spring extension.',
        );
      }
    }
    return null;
  }
}
