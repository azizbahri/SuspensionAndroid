import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/analysis_result.dart';

/// Line chart showing pitch angle (°) and longitudinal acceleration (g)
/// over time. Two vertically-stacked sub-charts share the same time axis,
/// mirroring the React PitchChart component.
class PitchChart extends StatelessWidget {
  const PitchChart({super.key, required this.data, required this.title});

  final PitchTrace data;
  final String title;

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
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(spacing: 16, runSpacing: 2, children: [
              _stat(context, 'Peak pitch', '${maxPitch.toStringAsFixed(1)}°'),
              _stat(context, 'Min pitch', '${minPitch.toStringAsFixed(1)}°'),
              _stat(context, 'Peak accel', '${maxAccel.toStringAsFixed(2)} g'),
              _stat(context, 'Min accel', '${minAccel.toStringAsFixed(2)} g'),
            ]),
            const SizedBox(height: 12),

            // ── Pitch sub-chart ──────────────────────────────────────────
            _subChartLabel('Pitch (°)', const Color(0xFF3B82F6)),
            SizedBox(
              height: 100,
              child: _lineChart(
                times: times,
                values: pitches,
                color: const Color(0xFF3B82F6),
                showBottomTitles: false,
              ),
            ),
            const SizedBox(height: 8),

            // ── Accel X sub-chart ────────────────────────────────────────
            _subChartLabel('Accel X (g)', const Color(0xFFF59E0B)),
            SizedBox(
              height: 100,
              child: _lineChart(
                times: times,
                values: accels,
                color: const Color(0xFFF59E0B),
                showBottomTitles: true,
              ),
            ),
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Time (s)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _subChartLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(children: [
          Container(width: 14, height: 2, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ]),
      );

  Widget _lineChart({
    required List<double> times,
    required List<double> values,
    required Color color,
    required bool showBottomTitles,
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
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: showBottomTitles,
              reservedSize: 18,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9),
              ),
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
