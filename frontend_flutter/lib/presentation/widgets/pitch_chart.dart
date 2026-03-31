import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analysis_result.dart';

/// Line chart showing pitch angle (°) and longitudinal acceleration (g)
/// over time. Two vertically-stacked sub-charts share the same time axis,
/// mirroring the React PitchChart component.
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
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No pitch data available.'),
        ),
      );
    }

    final maxPitch = pitches.reduce((a, b) => a > b ? a : b);
    final minPitch = pitches.reduce((a, b) => a < b ? a : b);
    final maxAccel = accels.reduce((a, b) => a > b ? a : b);
    final minAccel = accels.reduce((a, b) => a < b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
            ],
            if (title.isNotEmpty)
              Wrap(spacing: 16, runSpacing: 2, children: [
                _stat(context, 'Peak pitch', '${maxPitch.toStringAsFixed(1)}°'),
                _stat(context, 'Min pitch', '${minPitch.toStringAsFixed(1)}°'),
                _stat(context, 'Peak accel', '${maxAccel.toStringAsFixed(2)} g'),
                _stat(context, 'Min accel', '${minAccel.toStringAsFixed(2)} g'),
              ]),
            if (title.isNotEmpty) const SizedBox(height: 12),

            // ── Pitch sub-chart ──────────────────────────────────────────
            SizedBox(
              height: subChartHeight,
              child: _lineChart(
                times: times,
                values: pitches,
                color: const Color(0xFF3B82F6),
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
                color: const Color(0xFFF59E0B),
                showBottomTitles: true,
                yAxisLabel: 'Accel X (g)',
              ),
            ),
          ],
        ),
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
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 0,
            color: Colors.grey.shade400,
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
                      fontSize: 9, color: Color(0xFF6B7280))),
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
                  style: const TextStyle(fontSize: 9),
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
                        fontSize: 9, color: Color(0xFF6B7280)))
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
                  style: const TextStyle(fontSize: 9),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String label, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      );
}
