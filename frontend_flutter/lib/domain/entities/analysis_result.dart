import 'dart:convert';

/// Full analysis result produced by [SessionPipeline.process].
///
/// Mirrors the Python backend AnalysisResult Pydantic model 1:1.
class AnalysisResult {
  const AnalysisResult({
    required this.sessionId,
    required this.frontTravel,
    required this.rearTravel,
    required this.frontVelocity,
    required this.rearVelocity,
    required this.pitch,
    required this.diagnostics,
    required this.durationS,
    required this.sampleCount,
  });

  final String sessionId;
  final TravelHistogram frontTravel;
  final TravelHistogram rearTravel;
  final VelocityHistogram frontVelocity;
  final VelocityHistogram rearVelocity;
  final PitchTrace pitch;
  final List<DiagnosticNote> diagnostics;
  final double durationS;
  final int sampleCount;

  AnalysisResult copyWith({
    String? sessionId,
    TravelHistogram? frontTravel,
    TravelHistogram? rearTravel,
    VelocityHistogram? frontVelocity,
    VelocityHistogram? rearVelocity,
    PitchTrace? pitch,
    List<DiagnosticNote>? diagnostics,
    double? durationS,
    int? sampleCount,
  }) =>
      AnalysisResult(
        sessionId: sessionId ?? this.sessionId,
        frontTravel: frontTravel ?? this.frontTravel,
        rearTravel: rearTravel ?? this.rearTravel,
        frontVelocity: frontVelocity ?? this.frontVelocity,
        rearVelocity: rearVelocity ?? this.rearVelocity,
        pitch: pitch ?? this.pitch,
        diagnostics: diagnostics ?? this.diagnostics,
        durationS: durationS ?? this.durationS,
        sampleCount: sampleCount ?? this.sampleCount,
      );

  Map<String, dynamic> toJson() => {
        'session_id': sessionId,
        'front_travel': frontTravel.toJson(),
        'rear_travel': rearTravel.toJson(),
        'front_velocity': frontVelocity.toJson(),
        'rear_velocity': rearVelocity.toJson(),
        'pitch': pitch.toJson(),
        'diagnostics': diagnostics.map((d) => d.toJson()).toList(),
        'duration_s': durationS,
        'sample_count': sampleCount,
      };

  factory AnalysisResult.fromJson(Map<String, dynamic> json) => AnalysisResult(
        sessionId: json['session_id'] as String,
        frontTravel:
            TravelHistogram.fromJson(json['front_travel'] as Map<String, dynamic>),
        rearTravel:
            TravelHistogram.fromJson(json['rear_travel'] as Map<String, dynamic>),
        frontVelocity:
            VelocityHistogram.fromJson(json['front_velocity'] as Map<String, dynamic>),
        rearVelocity:
            VelocityHistogram.fromJson(json['rear_velocity'] as Map<String, dynamic>),
        pitch: PitchTrace.fromJson(json['pitch'] as Map<String, dynamic>),
        diagnostics: (json['diagnostics'] as List)
            .map((e) => DiagnosticNote.fromJson(e as Map<String, dynamic>))
            .toList(),
        durationS: (json['duration_s'] as num).toDouble(),
        sampleCount: json['sample_count'] as int,
      );

  String toJsonString() => jsonEncode(toJson());
  factory AnalysisResult.fromJsonString(String s) =>
      AnalysisResult.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

// ---------------------------------------------------------------------------
// Sub-models
// ---------------------------------------------------------------------------

class TravelHistogram {
  const TravelHistogram({
    required this.centersPct,
    required this.timePct,
    required this.peakCenterPct,
    required this.pctAbove80,
  });

  final List<double> centersPct;
  final List<double> timePct;
  final double peakCenterPct;
  final double pctAbove80;

  Map<String, dynamic> toJson() => {
        'centers_pct': centersPct,
        'time_pct': timePct,
        'peak_center_pct': peakCenterPct,
        'pct_above_80': pctAbove80,
      };

  factory TravelHistogram.fromJson(Map<String, dynamic> json) =>
      TravelHistogram(
        centersPct: (json['centers_pct'] as List).map((e) => (e as num).toDouble()).toList(),
        timePct: (json['time_pct'] as List).map((e) => (e as num).toDouble()).toList(),
        peakCenterPct: (json['peak_center_pct'] as num).toDouble(),
        pctAbove80: (json['pct_above_80'] as num).toDouble(),
      );
}

class VelocityHistogram {
  const VelocityHistogram({
    required this.centersMmS,
    required this.timePct,
    required this.compressionAreaPct,
    required this.reboundAreaPct,
    required this.lsCompressionPct,
    required this.hsCompressionPct,
    required this.lsReboundPct,
    required this.hsReboundPct,
  });

  final List<double> centersMmS;
  final List<double> timePct;
  final double compressionAreaPct;
  final double reboundAreaPct;
  final double lsCompressionPct;
  final double hsCompressionPct;
  final double lsReboundPct;
  final double hsReboundPct;

  Map<String, dynamic> toJson() => {
        'centers_mm_s': centersMmS,
        'time_pct': timePct,
        'compression_area_pct': compressionAreaPct,
        'rebound_area_pct': reboundAreaPct,
        'ls_compression_pct': lsCompressionPct,
        'hs_compression_pct': hsCompressionPct,
        'ls_rebound_pct': lsReboundPct,
        'hs_rebound_pct': hsReboundPct,
      };

  factory VelocityHistogram.fromJson(Map<String, dynamic> json) =>
      VelocityHistogram(
        centersMmS: (json['centers_mm_s'] as List)
            .map((e) => (e as num).toDouble())
            .toList(),
        timePct:
            (json['time_pct'] as List).map((e) => (e as num).toDouble()).toList(),
        compressionAreaPct:
            (json['compression_area_pct'] as num).toDouble(),
        reboundAreaPct: (json['rebound_area_pct'] as num).toDouble(),
        lsCompressionPct: (json['ls_compression_pct'] as num).toDouble(),
        hsCompressionPct: (json['hs_compression_pct'] as num).toDouble(),
        lsReboundPct: (json['ls_rebound_pct'] as num).toDouble(),
        hsReboundPct: (json['hs_rebound_pct'] as num).toDouble(),
      );
}

class PitchTrace {
  const PitchTrace({
    required this.timeS,
    required this.pitchDeg,
    required this.accelXG,
  });

  final List<double> timeS;
  final List<double> pitchDeg;
  final List<double> accelXG;

  Map<String, dynamic> toJson() => {
        'time_s': timeS,
        'pitch_deg': pitchDeg,
        'accel_x_g': accelXG,
      };

  factory PitchTrace.fromJson(Map<String, dynamic> json) => PitchTrace(
        timeS: (json['time_s'] as List).map((e) => (e as num).toDouble()).toList(),
        pitchDeg:
            (json['pitch_deg'] as List).map((e) => (e as num).toDouble()).toList(),
        accelXG:
            (json['accel_x_g'] as List).map((e) => (e as num).toDouble()).toList(),
      );
}

// ---------------------------------------------------------------------------
// Diagnostic note
// ---------------------------------------------------------------------------

enum DiagnosticSeverity { info, warning, critical }

class DiagnosticNote {
  const DiagnosticNote({
    required this.ruleId,
    required this.severity,
    required this.title,
    required this.message,
    required this.action,
  });

  final String ruleId;
  final DiagnosticSeverity severity;
  final String title;
  final String message;
  final String action;

  Map<String, dynamic> toJson() => {
        'rule_id': ruleId,
        'severity': severity.name,
        'title': title,
        'message': message,
        'action': action,
      };

  factory DiagnosticNote.fromJson(Map<String, dynamic> json) => DiagnosticNote(
        ruleId: json['rule_id'] as String,
        severity: DiagnosticSeverity.values.firstWhere(
          (e) => e.name == json['severity'],
          orElse: () => DiagnosticSeverity.info,
        ),
        title: json['title'] as String,
        message: json['message'] as String,
        action: json['action'] as String,
      );
}
