import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analysis_result.dart';

/// Line chart showing pitch angle (°) and longitudinal acceleration (g)
/// over time. Two vertically-stacked sub-charts share the same time axis,
/// mirroring the React PitchChart component.
///
/// Dark-themed: dark background, white-tinted grid, light axis labels.
class PitchChart extends StatelessWidget {
  const PitchChart({
    super.key,
    required this.data,
    required this.title,
    this.subChartHeight = 120,
  });

  final PitchTrace data;
  final String title;

  /// Height of each of the two sub-charts (pitch and accel).  Pass a value
  /// derived from [LayoutBuilder] constraints when using this chart full-screen.
  final double subChartHeight;

  // ── Dark chart palette ─────────────────────────────────────────────────────
  static const _bg = Color(0xFF111827);
  static const _gridColor = Color(0x26FFFFFF);
  static const _axisColor = Color(0xFFD1D5DB);

  @override
  Widget build(BuildContext context) {
    // Downsample for rendering performance on large captures.
    final step = data.timeS.length > 2000 ? 4 : 1;
    final times = <double>[];
    final pitches = <double>[];
    final accels = <double>[];
    for (int i = 0; i < data.timeS.length; i += step) {
      times.add(data.timeS[i]);
      pitches.add(data.pitchDeg[i]);
      accels.add(data.accelXG[i]);
    }

    if (times.isEmpty) {
      return Container(
        color: _bg,
        padding: const EdgeInsets.all(16),
        child: const Text('No pitch data available.',
            style: TextStyle(color: Colors.white70)),
      );
    }

    final maxPitch = pitches.reduce((a, b) => a > b ? a : b);
    final minPitch = pitches.reduce((a, b) => a < b ? a : b);
    final maxAccel = accels.reduce((a, b) => a > b ? a : b);
    final minAccel = accels.reduce((a, b) => a < b ? a : b);

    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
          ],
          if (title.isNotEmpty)
            Wrap(spacing: 16, runSpacing: 2, children: [
              _stat('Peak pitch', '${maxPitch.toStringAsFixed(1)}°'),
              _stat('Min pitch', '${minPitch.toStringAsFixed(1)}°'),
              _stat('Peak accel', '${maxAccel.toStringAsFixed(2)} g'),
              _stat('Min accel', '${minAccel.toStringAsFixed(2)} g'),
            ]),
          if (title.isNotEmpty) const SizedBox(height: 12),

          // ── Pitch sub-chart ──────────────────────────────────────────
          SizedBox(
            height: subChartHeight,
            child: _lineChart(
              times: times,
              values: pitches,
              color: const Color(0xFF60A5FA), // blue-400
              showBottomTitles: false,
              yAxisLabel: 'Pitch (°)',
            ),
          ),
          const SizedBox(height: 8),

          // ── Accel X sub-chart ────────────────────────────────────────
          SizedBox(
            height: subChartHeight,
            child: _lineChart(
              times: times,
              values: accels,
              color: const Color(0xFFFBBF24), // amber-400
              showBottomTitles: true,
              yAxisLabel: 'Accel X (g)',
            ),
          ),
        ],
      ),
    );
  }

  Widget _lineChart({
    required List<double> times,
    required List<double> values,
    required Color color,
    required bool showBottomTitles,
    required String yAxisLabel,
  }) {
    final spots = <FlSpot>[
      for (int i = 0; i < times.length; i++) FlSpot(times[i], values[i]),
    ];

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: color,
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF374151)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: _gridColor, strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              FlLine(color: _gridColor, strokeWidth: 1),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Colors.white30,
            strokeWidth: 1,
            dashArray: [4, 4],
          ),
        ]),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            axisNameWidget: RotatedBox(
              quarterTurns: -1,
              child: Text(yAxisLabel,
                  style: const TextStyle(
                      fontSize: 9, color: _axisColor)),
            ),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 9, color: _axisColor),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: showBottomTitles
                ? const Text('Time (s)',
                    style: TextStyle(
                        fontSize: 9, color: _axisColor))
                : null,
            axisNameSize: showBottomTitles ? 16 : 0,
            sideTitles: SideTitles(
              showTitles: showBottomTitles,
              reservedSize: 18,
              getTitlesWidget: (v, meta) {
                if (v == meta.max || v == meta.min) {
                  return const SizedBox.shrink();
                }
                return Text(
                  v.toStringAsFixed(0),
                  style: const TextStyle(
                      fontSize: 9, color: _axisColor),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ',
              style: const TextStyle(fontSize: 11, color: _axisColor)),
          Text(value,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ],
      );
}
