import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';
import '../../domain/entities/analysis_result.dart';

/// Bar chart showing travel percentage distribution.
///
/// Mirrors the React TravelHistogram component.
/// Reference lines at 30% (ideal sag, green) and 80% (deep-stroke limit, red).
class TravelHistogramChart extends StatelessWidget {
  const TravelHistogramChart({
    super.key,
    required this.data,
    required this.title,
  });

  final TravelHistogram data;
  final String title;

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
            Row(children: [
              _stat(context, 'Peak', FormatUtils.formatPct(data.peakCenterPct)),
              const SizedBox(width: 16),
              _stat(context, 'Above 80%',
                  FormatUtils.formatPct(data.pctAbove80)),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              height: 210,
              child: BarChart(
                BarChartData(
                  minY: 0,
                  // Use actual travel-% values as x positions so reference
                  // lines at 30 and 80 land on the correct bars.
                  barGroups: _buildBars(),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    // Y axis: Time (%)
                    leftTitles: AxisTitles(
                      axisNameWidget: const RotatedBox(
                        quarterTurns: -1,
                        child: Text('Time (%)',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF6B7280))),
                      ),
                      axisNameSize: 18,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (value, meta) {
                          if (value == meta.max) {
                            return const SizedBox.shrink();
                          }
                          if (value % 5 != 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    // X axis: Travel (%)
                    bottomTitles: AxisTitles(
                      axisNameWidget: const Text('Travel (%)',
                          style: TextStyle(
                              fontSize: 10, color: Color(0xFF6B7280))),
                      axisNameSize: 18,
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        getTitlesWidget: (value, meta) {
                          if (value % 20 != 0) return const SizedBox.shrink();
                          return Text(
                            '${value.toInt()}%',
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(verticalLines: [
                    VerticalLine(
                      x: 30,
                      color: Colors.green,
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (_) => 'Sag',
                        style:
                            const TextStyle(fontSize: 9, color: Colors.green),
                      ),
                    ),
                    VerticalLine(
                      x: 80,
                      color: Colors.red,
                      strokeWidth: 1.5,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (_) => '80%',
                        style: const TextStyle(fontSize: 9, color: Colors.red),
                      ),
                    ),
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
    for (int i = 0; i < data.centersPct.length; i++) {
      groups.add(BarChartGroupData(
        // Use actual travel-% value so reference lines align correctly.
        x: data.centersPct[i].round(),
        barRods: [
          BarChartRodData(
            toY: data.timePct[i],
            color: const Color(0xFFF97316), // orange-500
            width: 14,
            borderRadius: BorderRadius.zero,
          ),
        ],
      ));
    }
    return groups;
  }

  Widget _stat(BuildContext context, String label, String value) => Row(
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

