import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';
import '../../domain/entities/analysis_result.dart';

/// Bar chart showing suspension velocity distribution.
///
/// Negative = compression (red), Positive = rebound (green).
/// Reference lines at 0 mm/s, ±150 mm/s (LS/HS threshold).
class VelocityHistogramChart extends StatelessWidget {
  const VelocityHistogramChart({
    super.key,
    required this.data,
    required this.title,
    this.lsThresholdMmS = 150.0,
  });

  final VelocityHistogram data;
  final String title;
  final double lsThresholdMmS;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Wrap(spacing: 12, children: [
              _stat(context, 'Comp',
                  FormatUtils.formatPct(data.compressionAreaPct)),
              _stat(context, 'Reb',
                  FormatUtils.formatPct(data.reboundAreaPct)),
              _stat(context, 'LS-C',
                  FormatUtils.formatPct(data.lsCompressionPct)),
              _stat(context, 'HS-C',
                  FormatUtils.formatPct(data.hsCompressionPct)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  barGroups: _buildBars(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: (value, meta) {
                          if (value % 500 != 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(verticalLines: [
                    VerticalLine(x: 0, color: Colors.grey, strokeWidth: 1),
                    VerticalLine(
                        x: lsThresholdMmS,
                        color: Colors.blue.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [4, 4]),
                    VerticalLine(
                        x: -lsThresholdMmS,
                        color: Colors.blue.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [4, 4]),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBars() {
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < data.centersMmS.length; i++) {
      final center = data.centersMmS[i];
      final color = center < 0 ? Colors.red.shade400 : Colors.green.shade400;
      groups.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data.timePct[i],
            color: color,
            width: 4,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }
    return groups;
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
