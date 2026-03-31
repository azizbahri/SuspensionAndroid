import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';
import '../../domain/entities/analysis_result.dart';

/// Bar chart showing travel percentage distribution.
///
/// Mirrors the React TravelHistogram component.
/// Reference lines at 30% (ideal sag, green) and 80% (deep-stroke limit, red).
///
/// Dark-themed: dark background, white-tinted grid, light axis labels.
class TravelHistogramChart extends StatelessWidget {
  const TravelHistogramChart({
    super.key,
    required this.data,
    required this.title,
    this.chartHeight = 210,
  });

  final TravelHistogram data;
  final String title;

  /// Height of the inner BarChart widget.  Pass a value derived from
  /// [LayoutBuilder] constraints when using this chart full-screen.
  final double chartHeight;

  // ── Dark chart palette ─────────────────────────────────────────────────────
  static const _bg = Color(0xFF111827);          // gray-900
  static const _gridColor = Color(0x26FFFFFF);   // white 15 %
  static const _axisColor = Color(0xFFD1D5DB);   // gray-300
  static const _borderColor = Color(0xFF374151); // gray-700

  @override
  Widget build(BuildContext context) {
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
            Row(children: [
              _stat('Peak', FormatUtils.formatPct(data.peakCenterPct)),
              const SizedBox(width: 16),
              _stat('Above 80%', FormatUtils.formatPct(data.pctAbove80)),
            ]),
          if (title.isNotEmpty) const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                minY: 0,
                // Use actual travel-% values as x positions so reference
                // lines at 30 and 80 land on the correct bars.
                barGroups: _buildBars(),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: _borderColor),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
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
                              fontSize: 10, color: _axisColor)),
                    ),
                    axisNameSize: 18,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        if (value % 5 != 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                              fontSize: 9, color: _axisColor),
                        );
                      },
                    ),
                  ),
                  // X axis: Travel (%)
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Travel (%)',
                        style: TextStyle(fontSize: 10, color: _axisColor)),
                    axisNameSize: 18,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        if (value % 20 != 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}%',
                          style: const TextStyle(
                              fontSize: 9, color: _axisColor),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(verticalLines: [
                  VerticalLine(
                    x: 30,
                    color: Colors.greenAccent,
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Sag',
                      style: const TextStyle(
                          fontSize: 9, color: Colors.greenAccent),
                    ),
                  ),
                  VerticalLine(
                    x: 80,
                    color: Colors.redAccent,
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                    label: VerticalLineLabel(
                      show: true,
                      labelResolver: (_) => '80%',
                      style: const TextStyle(
                          fontSize: 9, color: Colors.redAccent),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ],
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

