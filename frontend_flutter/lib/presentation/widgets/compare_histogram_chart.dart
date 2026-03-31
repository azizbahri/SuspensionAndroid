import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One data series (one session) for the comparison chart.
class CompareSeriesData {
  const CompareSeriesData({
    required this.label,
    required this.color,
    required this.values,
  });

  /// Session name displayed in the legend.
  final String label;

  /// Bar / legend colour for this session.
  final Color color;

  /// Time-percentage value for each bin (parallel to [CompareHistogramChart.binCenters]).
  final List<double> values;
}

/// Multi-session grouped bar chart used on the Compare page.
///
/// Each bin position gets one bar per session, rendered side-by-side in the
/// session colour. Dark-themed: dark background, white grid, light labels.
class CompareHistogramChart extends StatefulWidget {
  const CompareHistogramChart({
    super.key,
    required this.binCenters,
    required this.series,
    required this.xAxisLabel,
    required this.yAxisLabel,
    this.referenceLines = const [],
  });

  /// X positions of each histogram bin (travel % or velocity mm/s).
  final List<double> binCenters;

  /// One entry per session being compared.
  ///
  /// **Invariant:** every [CompareSeriesData.values] list must have exactly
  /// the same length as [binCenters].  Mismatched lengths are treated as
  /// missing bins and rendered as 0 % time.
  final List<CompareSeriesData> series;

  final String xAxisLabel;
  final String yAxisLabel;

  /// Optional reference lines drawn at fixed x positions.
  final List<VerticalLine> referenceLines;

  @override
  State<CompareHistogramChart> createState() => _CompareHistogramChartState();
}

class _CompareHistogramChartState extends State<CompareHistogramChart> {
  int? _touchedGroupIndex;

  // ── Dark chart palette ─────────────────────────────────────────────────────
  static const _bg = Color(0xFF111827);
  static const _gridColor = Color(0x26FFFFFF);
  static const _axisColor = Color(0xFFD1D5DB);
  static const _borderColor = Color(0xFF374151);

  // ---------------------------------------------------------------------------
  // Bar geometry
  // ---------------------------------------------------------------------------

  double get _barWidth {
    final n = widget.series.length.clamp(1, 3);
    // Target total group width ≈ 14 px; each extra bar shrinks individual width.
    return ((14.0 - (n - 1) * 2.0) / n).clamp(3.0, 14.0);
  }

  // ---------------------------------------------------------------------------
  // Axis tick helpers
  // ---------------------------------------------------------------------------

  bool get _isVelocity => widget.binCenters.any((c) => c < 0);

  Widget _xTitleWidget(double value, TitleMeta meta) {
    // Use integer modulo to avoid floating-point precision issues.
    final step = _isVelocity ? 500 : 20;
    if (value.round() % step != 0) return const SizedBox.shrink();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        value.toInt().toString(),
        style: const TextStyle(fontSize: 9, color: Color(0xFFD1D5DB)),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Groups
  // ---------------------------------------------------------------------------

  List<BarChartGroupData> _buildGroups() {
    final groups = <BarChartGroupData>[];
    for (int i = 0; i < widget.binCenters.length; i++) {
      final rods = <BarChartRodData>[];
      for (final s in widget.series) {
        final val = i < s.values.length ? s.values[i] : 0.0;
        rods.add(BarChartRodData(
          toY: val,
          color: s.color.withOpacity(0.85),
          width: _barWidth,
          borderRadius: BorderRadius.zero,
        ));
      }
      groups.add(BarChartGroupData(
        x: widget.binCenters[i].round(),
        barRods: rods,
        barsSpace: 2,
        showingTooltipIndicators:
            _touchedGroupIndex == i ? List.generate(rods.length, (j) => j) : [],
      ));
    }
    return groups;
  }

  // ---------------------------------------------------------------------------
  // Tooltip
  // ---------------------------------------------------------------------------

  BarTooltipItem? _tooltipItem(
    BarChartGroupData group,
    int groupIndex,
    BarChartRodData rod,
    int rodIndex,
  ) {
    if (rodIndex >= widget.series.length) return null;
    final s = widget.series[rodIndex];
    final xLabel = _isVelocity
        ? '${group.x} mm/s'
        : '${group.x}%';
    return BarTooltipItem(
      '${s.label}\n$xLabel\n${rod.toY.toStringAsFixed(1)}%',
      TextStyle(
        color: s.color,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Legend ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: widget.series
                  .map((s) => _LegendItem(color: s.color, label: s.label))
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),

          // ── Chart ───────────────────────────────────────────────────────────
          Expanded(
            child: BarChart(
              BarChartData(
                minY: 0,
                barGroups: _buildGroups(),

                // Dark border frame.
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: _borderColor),
                ),

                // Full grid: white-tinted H and V lines.
                gridData: FlGridData(
                  show: true,
                  drawHorizontalLine: true,
                  drawVerticalLine: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: _gridColor, strokeWidth: 1),
                ),

                // Axis titles.
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  // Y axis — Time (%)
                  leftTitles: AxisTitles(
                    axisNameWidget: RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        widget.yAxisLabel,
                        style: const TextStyle(
                            fontSize: 11, color: _axisColor),
                      ),
                    ),
                    axisNameSize: 22,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      getTitlesWidget: (value, meta) {
                        if (value == meta.max) return const SizedBox.shrink();
                        if (value % 5 != 0) return const SizedBox.shrink();
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            '${value.toInt()}',
                            style: const TextStyle(
                                fontSize: 9, color: _axisColor),
                          ),
                        );
                      },
                    ),
                  ),
                  // X axis — Travel (%) or Velocity (mm/s)
                  bottomTitles: AxisTitles(
                    axisNameWidget: Text(
                      widget.xAxisLabel,
                      style: const TextStyle(
                          fontSize: 11, color: _axisColor),
                    ),
                    axisNameSize: 22,
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: _xTitleWidget,
                    ),
                  ),
                ),

                // Reference lines (sag, bottoming, LS/HS, etc.).
                extraLinesData: ExtraLinesData(
                  verticalLines: widget.referenceLines,
                ),

                // Touch tooltip.
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (response != null &&
                          response.spot != null &&
                          event is! FlTapUpEvent &&
                          event is! FlPointerExitEvent) {
                        _touchedGroupIndex =
                            response.spot!.touchedBarGroupIndex;
                      } else {
                        _touchedGroupIndex = null;
                      }
                    });
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        const Color(0xFF1F2937).withOpacity(0.92),
                    getTooltipItem: _tooltipItem,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Legend item
// ---------------------------------------------------------------------------

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
      ],
    );
  }
}
