import 'package:flutter/material.dart';

import '../../domain/entities/analysis_result.dart';
import 'diagnostic_card.dart';

// ---------------------------------------------------------------------------
// Chart key enum
// ---------------------------------------------------------------------------

/// Identifies which chart was tapped in the Analyze screen.
enum ChartKey {
  frontTravel,
  rearTravel,
  frontVelocity,
  rearVelocity,
  pitch,
}

// ---------------------------------------------------------------------------
// Static info tables (mirrors ChartDetailSidebar.tsx)
// ---------------------------------------------------------------------------

class _ChartInfo {
  const _ChartInfo({
    required this.title,
    required this.description,
    required this.interpretation,
  });
  final String title;
  final String description;
  final List<String> interpretation;
}

const _kChartInfo = <ChartKey, _ChartInfo>{
  ChartKey.frontTravel: _ChartInfo(
    title: 'Front Travel Distribution',
    description:
        'Shows how the front fork travel is distributed across the session. '
        'Each bar represents the percentage of total ride time spent at that '
        'travel depth, expressed as a fraction of maximum available stroke.',
    interpretation: [
      'Green reference line at 30 % = ideal sag target. At rest under rider '
          'weight the fork should sit here, leaving stroke to extend over drops '
          'and compression ruts.',
      'Red reference line at 80 % = bottoming-zone threshold. Time spent above '
          'this line risks coil-spring or oil-lock bottoming.',
      'Peak bucket shows where the fork spends most time. A healthy setup peaks '
          'near the sag point (25–35 %).',
      'Peak far below 25 %: spring may be too stiff or preload too high. '
          'Peak above 40 %: spring too soft or compression damping too low.',
      '"Above 80 %" time exceeding 5–10 % suggests the fork needs a stiffer '
          'spring or more high-speed compression damping.',
    ],
  ),
  ChartKey.rearTravel: _ChartInfo(
    title: 'Rear Travel Distribution',
    description:
        'Shows how the rear shock travel is distributed across the session. '
        'Each bar represents the percentage of total ride time spent at that '
        'travel depth, expressed as a fraction of maximum available stroke.',
    interpretation: [
      'Green reference line at 30 % = ideal sag target. Rear sag is typically '
          'set to 25–30 % of stroke under rider weight.',
      'Red reference line at 80 % = bottoming threshold. Consistent time above '
          'this zone indicates the shock needs a stiffer spring.',
      'Peak bucket near sag = balanced setup. A peak shifted right suggests '
          'the spring is too soft or the shock needs more preload.',
      'Rear suspension sees acceleration-induced squat; a slight right bias '
          'compared to the front is normal during hard acceleration zones.',
    ],
  ),
  ChartKey.frontVelocity: _ChartInfo(
    title: 'Front Damper Velocity Distribution',
    description:
        'Histogram of front fork shaft velocity. Negative values (red bars) '
        'are compression strokes; positive values (green bars) are rebound '
        'strokes. The ±150 mm/s boundaries split low-speed from high-speed '
        'damping zones.',
    interpretation: [
      'Low-speed compression (LS-C, |v| < 150 mm/s): controls body-motion '
          'damping over smooth terrain. Adjusted by the LSC clicker.',
      'High-speed compression (HS-C, |v| > 150 mm/s): controls impact response '
          'on square-edge hits. Adjusted by the HSC adjuster.',
      'Low-speed rebound (LS-R): governs how fast the fork returns from '
          'body-motion compressions. Too slow = packing; too fast = headshake.',
      'High-speed rebound (HS-R): controls kick-back after sharp impacts. '
          'Too fast = harsh feel; too slow = packing on successive bumps.',
      'A roughly symmetric compression/rebound split indicates balanced '
          'damping. Heavy compression bias may mean under-damped compression '
          'or very aggressive terrain.',
    ],
  ),
  ChartKey.rearVelocity: _ChartInfo(
    title: 'Rear Damper Velocity Distribution',
    description:
        'Histogram of rear shock shaft velocity. Negative values (red bars) '
        'are compression strokes; positive values (green bars) are rebound '
        'strokes. The ±150 mm/s thresholds split low-speed from high-speed '
        'damping zones.',
    interpretation: [
      'LS-C zone governs body squat damping under acceleration and braking '
          'forces. Adjust with the LSC clicker.',
      'HS-C zone governs impact absorption on roots, rocks, and drops. '
          'Adjust with the HSC adjuster.',
      'LS-R governs recovery from body-motion compressions. Too slow = '
          'brake-induced packing on rough descents.',
      'HS-R governs recovery from sharp impacts. Too fast causes rear bounce; '
          'too slow causes packing on repeated hits.',
      'Rear shock sees more compression during acceleration and more rebound '
          'during braking — a slight asymmetry is expected.',
    ],
  ),
  ChartKey.pitch: _ChartInfo(
    title: 'Pitch & Acceleration Trace',
    description:
        'Time-series of chassis pitch angle (°) and longitudinal acceleration '
        '(g) over the session. Pitch is estimated with a complementary filter '
        '(α = 0.98) that fuses the gyroscope (short-term accuracy) with the '
        'accelerometer gravity reference (long-term drift correction).',
    interpretation: [
      'Negative pitch angle = nose-down (braking event, steep descent). '
          'Positive = nose-up (acceleration, climb).',
      'Braking events appear as synchronized negative pitch + negative '
          'acceleration spikes.',
      'Hard acceleration events appear as positive pitch + positive '
          'acceleration.',
      'The complementary filter prevents gyro bias from accumulating over the '
          'session while rejecting vibration artifacts in the accelerometer.',
      'Large sustained negative pitch during descents is normal. Abrupt pitch '
          'transitions indicate sharp terrain or high-intensity rider inputs.',
    ],
  ),
};

// Map chart keys → diagnostic rule_id prefixes for filtering
const _kChartDiagPrefixes = <ChartKey, List<String>>{
  ChartKey.frontTravel: ['front_travel', 'front'],
  ChartKey.rearTravel: ['rear_travel', 'rear'],
  ChartKey.frontVelocity: ['front_velocity', 'front'],
  ChartKey.rearVelocity: ['rear_velocity', 'rear'],
  ChartKey.pitch: ['pitch', 'imu', 'accel'],
};

// ---------------------------------------------------------------------------
// Key-metrics widgets
// ---------------------------------------------------------------------------

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.warn = false});
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: warn ? Colors.red.shade700 : Colors.grey.shade900)),
          ],
        ),
      );
}

Widget _buildKeyMetrics(ChartKey key, AnalysisResult result) {
  switch (key) {
    case ChartKey.frontTravel:
    case ChartKey.rearTravel:
      final d = key == ChartKey.frontTravel
          ? result.frontTravel
          : result.rearTravel;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        _Metric(label: 'Peak Travel', value: '${d.peakCenterPct.toStringAsFixed(1)} %'),
        _Metric(
          label: 'Time Above 80 %',
          value: '${d.pctAbove80.toStringAsFixed(1)} %',
          warn: d.pctAbove80 > 10,
        ),
      ]);

    case ChartKey.frontVelocity:
    case ChartKey.rearVelocity:
      final d = key == ChartKey.frontVelocity
          ? result.frontVelocity
          : result.rearVelocity;
      return Wrap(spacing: 8, runSpacing: 8, children: [
        _Metric(label: 'Compression', value: '${d.compressionAreaPct.toStringAsFixed(1)} %'),
        _Metric(label: 'Rebound', value: '${d.reboundAreaPct.toStringAsFixed(1)} %'),
        _Metric(label: 'LS-Compression', value: '${d.lsCompressionPct.toStringAsFixed(1)} %'),
        _Metric(label: 'HS-Compression', value: '${d.hsCompressionPct.toStringAsFixed(1)} %'),
        _Metric(label: 'LS-Rebound', value: '${d.lsReboundPct.toStringAsFixed(1)} %'),
        _Metric(label: 'HS-Rebound', value: '${d.hsReboundPct.toStringAsFixed(1)} %'),
      ]);

    case ChartKey.pitch:
      final d = result.pitch;
      final maxP = d.pitchDeg.reduce((a, b) => a > b ? a : b);
      final minP = d.pitchDeg.reduce((a, b) => a < b ? a : b);
      final maxA = d.accelXG.reduce((a, b) => a > b ? a : b);
      final minA = d.accelXG.reduce((a, b) => a < b ? a : b);
      return Wrap(spacing: 8, runSpacing: 8, children: [
        _Metric(label: 'Peak Pitch (nose-up)', value: '${maxP.toStringAsFixed(1)} °'),
        _Metric(label: 'Min Pitch (nose-down)', value: '${minP.toStringAsFixed(1)} °'),
        _Metric(label: 'Peak Accel', value: '${maxA.toStringAsFixed(2)} g'),
        _Metric(label: 'Min Accel (braking)', value: '${minA.toStringAsFixed(2)} g'),
      ]);
  }
}

// ---------------------------------------------------------------------------
// Main panel widget
// ---------------------------------------------------------------------------

/// Sliding right-side info panel for chart details.
///
/// Animated with [AnimatedPositioned] so it slides in/out from the right.
/// Wrap the Analyze screen content in a [Stack] and put this as the last child.
class ChartDetailPanel extends StatelessWidget {
  const ChartDetailPanel({
    super.key,
    required this.chartKey,
    required this.result,
    required this.onClose,
    this.panelWidth = 320,
  });

  final ChartKey chartKey;
  final AnalysisResult result;
  final VoidCallback onClose;
  final double panelWidth;

  @override
  Widget build(BuildContext context) {
    final info = _kChartInfo[chartKey]!;
    final prefixes = _kChartDiagPrefixes[chartKey]!;
    final relatedDiags = result.diagnostics.where((d) {
      final id = d.ruleId.toLowerCase();
      return prefixes.any((p) => id.startsWith(p));
    }).toList();

    return Material(
      elevation: 8,
      color: Colors.white,
      child: SizedBox(
        width: panelWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Row(children: [
                Expanded(
                  child: Text(info.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ]),
            ),
            const Divider(height: 1),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Description
                      _sectionLabel('What this chart shows'),
                      Text(info.description,
                          style: const TextStyle(
                              fontSize: 13, height: 1.5,
                              color: Color(0xFF374151))),
                      const SizedBox(height: 16),

                      // Key metrics
                      _sectionLabel('Key Metrics'),
                      _buildKeyMetrics(chartKey, result),
                      const SizedBox(height: 16),

                      // Interpretation
                      _sectionLabel('How to interpret'),
                      ...info.interpretation.map((tip) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                const Text('·',
                                    style: TextStyle(
                                        color: Color(0xFFF97316),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        height: 1.2)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(tip,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          height: 1.5,
                                          color: Color(0xFF374151))),
                                ),
                              ],
                            ),
                          )),

                      // Related diagnostics
                      if (relatedDiags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _sectionLabel('Related Diagnostics'),
                        ...relatedDiags.map((d) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 8),
                              child: DiagnosticCard(note: d),
                            )),
                      ],
                    ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
                letterSpacing: 0.8)),
      );
}
