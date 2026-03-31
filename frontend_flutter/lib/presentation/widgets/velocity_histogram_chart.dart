import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/utils/format_utils.dart';
import '../../domain/entities/analysis_result.dart';

/// Bar chart showing suspension velocity distribution.
///
/// Negative = compression (red), Positive = rebound (green).
/// Reference lines at 0 mm/s, ±150 mm/s (LS/HS threshold).
///
/// Dark-themed: dark background, white-tinted grid, light axis labels.
class VelocityHistogramChart extends StatelessWidget {
  const VelocityHistogramChart({
    super.key,
    required this.data,
    required this.title,
    this.lsThresholdMmS = 150.0,
    this.chartHeight = 210,
  });

  final VelocityHistogram data;
  final String title;
  final double lsThresholdMmS;

  /// Height of the inner BarChart widget.  Pass a value derived from
  /// [LayoutBuilder] constraints when using this chart full-screen.
  final double chartHeight;

  // ── Dark chart palette ─────────────────────────────────────────────────────
  static const _bg = Color(0xFF111827);
  static const _gridColor = Color(0x26FFFFFF);
  static const _axisColor = Color(0xFFD1D5DB);
  static const _borderColor = Color(0xFF374151);

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
            Wrap(spacing: 12, children: [
              _stat('Comp', FormatUtils.formatPct(data.compressionAreaPct)),
              _stat('Reb', FormatUtils.formatPct(data.reboundAreaPct)),
              _stat('LS-C', FormatUtils.formatPct(data.lsCompressionPct)),
              _stat('HS-C', FormatUtils.formatPct(data.hsCompressionPct)),
            ]),
          if (title.isNotEmpty) const SizedBox(height: 8),
          SizedBox(
            height: chartHeight,
            child: BarChart(
              BarChartData(
                minY: 0,
                // Use actual velocity values as x positions so reference
                // lines at 0 and ±150 mm/s land on the correct bins.
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
                  // X axis: Velocity (mm/s)
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text('Velocity (mm/s)',
                        style: TextStyle(fontSize: 10, color: _axisColor)),
                    axisNameSize: 18,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      getTitlesWidget: (value, meta) {
                        if (value % 500 != 0) return const SizedBox.shrink();
                        return Text(
                          '${value.toInt()}',
                          style: const TextStyle(
                              fontSize: 9, color: _axisColor),
                        );
                      },
                    ),
                  ),
                ),
                extraLinesData: ExtraLinesData(verticalLines: [
                  VerticalLine(
                      x: 0,
                      color: Colors.white54,
                      strokeWidth: 1.2),
                  VerticalLine(
                      x: lsThresholdMmS,
                      color: const Color(0xFF60A5FA), // blue-400
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (_) => 'LS|HS',
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF93C5FD)),
                      )),
                  VerticalLine(
                      x: -lsThresholdMmS,
                      color: const Color(0xFF60A5FA),
                      strokeWidth: 1,
                      dashArray: [4, 4],
                      label: VerticalLineLabel(
                        show: true,
                        labelResolver: (_) => 'LS|HS',
                        style: const TextStyle(
                            fontSize: 8, color: Color(0xFF93C5FD)),
                      )),
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
    for (int i = 0; i < data.centersMmS.length; i++) {
      final center = data.centersMmS[i];
      // Bright red for compression, bright green for rebound on dark bg.
      final color = center < 0
          ? const Color(0xFFF87171) // red-400
          : const Color(0xFF4ADE80); // green-400
      groups.add(BarChartGroupData(
        // Use actual velocity value so reference lines align correctly.
        x: center.round(),
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

