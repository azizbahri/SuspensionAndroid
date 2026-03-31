import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/repositories/analysis_repository.dart';
import '../../providers/providers.dart';
import '../../widgets/compare_histogram_chart.dart';
import '../../widgets/error_banner.dart';

// ---------------------------------------------------------------------------
// Graph-type enum
// ---------------------------------------------------------------------------

enum _GraphType {
  frontTravel,
  rearTravel,
  frontVelocity,
  rearVelocity;

  String get label => switch (this) {
        frontTravel => 'Front Travel',
        rearTravel => 'Rear Travel',
        frontVelocity => 'Front Velocity',
        rearVelocity => 'Rear Velocity',
      };

  IconData get icon => switch (this) {
        frontTravel || rearTravel => Icons.stacked_bar_chart,
        frontVelocity || rearVelocity => Icons.speed,
      };
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Compare up to 3 analyzed sessions side-by-side.
///
/// Two modes:
///  - **Selector view** (no results yet): compact scrollable session list +
///    Compare button.
///  - **Chart view** (results available): single full-screen chart in an
///    [InteractiveViewer] (pinch-zoom + pan). A floating mini FAB expands
///    upward into pill-shaped graph-type buttons.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  // ── Session selection ──────────────────────────────────────────────────────
  final _selectedIds = <String>{};
  bool _comparing = false;
  String? _error;
  List<SessionCompareEntry>? _results;

  // ── Graph view state ───────────────────────────────────────────────────────
  _GraphType _activeGraph = _GraphType.frontTravel;
  bool _graphMenuOpen = false;

  static const _sessionColors = <Color>[
    Color(0xFFF97316), // orange-500
    Color(0xFF3B82F6), // blue-500
    Color(0xFFA855F7), // purple-500
  ];

  // ---------------------------------------------------------------------------
  // Compare action
  // ---------------------------------------------------------------------------

  Future<void> _compare() async {
    setState(() {
      _comparing = true;
      _error = null;
    });

    final result =
        await ref.read(compareSessionsUseCaseProvider)(_selectedIds.toList());

    setState(() => _comparing = false);

    result.fold(
      onSuccess: (r) => setState(() => _results = r.sessions),
      onFailure: (e) => setState(() {
        _error = e.message;
        _results = null;
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final showingChart = _results != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(showingChart ? _activeGraph.label : 'Compare Sessions'),
        actions: showingChart
            ? [
                TextButton.icon(
                  onPressed: () => setState(() {
                    _results = null;
                    _graphMenuOpen = false;
                  }),
                  icon: const Icon(Icons.group, size: 16, color: Colors.white),
                  label: const Text('Sessions',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ]
            : null,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: _buildBody,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body router
  // ---------------------------------------------------------------------------

  Widget _buildBody(List<Session> sessions) {
    if (_results != null) return _buildChartView();
    return _buildSelectorView(sessions);
  }

  // ---------------------------------------------------------------------------
  // Selector view
  // ---------------------------------------------------------------------------

  Widget _buildSelectorView(List<Session> sessions) {
    final analyzed = sessions.where((s) => s.analyzed).toList();

    if (analyzed.isEmpty) {
      return const Center(
        child: Text(
          'No analyzed sessions available.\n'
          'Import or simulate a session and analyze it first.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null)
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),

        // ── Label ────────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            const Expanded(
              child: Text('Select 2–3 sessions to compare:',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            ),
            if (_selectedIds.isNotEmpty)
              Text('${_selectedIds.length} selected',
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFF97316))),
          ]),
        ),

        // ── Scrollable session list — capped at 280 px ────────────────────
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: SingleChildScrollView(
            child: Column(
              children: analyzed.map((session) {
                final isSelected = _selectedIds.contains(session.id);
                final isDisabled =
                    !isSelected && _selectedIds.length >= 3;
                final colorIndex = _selectedIds
                    .toList()
                    .indexOf(session.id)
                    .clamp(0, 2);
                return CheckboxListTile(
                  dense: true,
                  title: Text(session.name,
                      style: const TextStyle(fontSize: 13)),
                  subtitle: Text(session.bikeSlug,
                      style: const TextStyle(fontSize: 11)),
                  secondary: isSelected
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _sessionColors[colorIndex],
                            shape: BoxShape.circle,
                          ),
                        )
                      : null,
                  value: isSelected,
                  onChanged: isDisabled
                      ? null
                      : (v) => setState(() {
                            if (v == true) {
                              _selectedIds.add(session.id);
                            } else {
                              _selectedIds.remove(session.id);
                            }
                          }),
                );
              }).toList(),
            ),
          ),
        ),

        // ── Compare button ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (_selectedIds.length >= 2 && !_comparing) ? _compare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
              ),
              child: _comparing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Compare'),
            ),
          ),
        ),

        const Expanded(
          child: Center(
            child: Text(
              'Select sessions above, then press Compare',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Full-screen chart view
  // ---------------------------------------------------------------------------

  Widget _buildChartView() {
    return Stack(
      children: [
        // ── Full-screen chart ───────────────────────────────────────────────
        Positioned.fill(
          child: LayoutBuilder(
            builder: (ctx, c) => InteractiveViewer(
              scaleEnabled: true,
              panEnabled: true,
              minScale: 0.5,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: SizedBox(
                width: c.maxWidth,
                height: c.maxHeight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 52, 8, 8),
                  child: _buildActiveChart(),
                ),
              ),
            ),
          ),
        ),

        // ── Stats overlay (semi-transparent top bar) ────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: _buildStatsRow(),
          ),
        ),

        // ── Backdrop — closes menu when tapping elsewhere ───────────────────
        if (_graphMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _graphMenuOpen = false),
              child: const ColoredBox(color: Color(0x44000000)),
            ),
          ),

        // ── Floating graph-type menu (grows upward from FAB) ────────────────
        if (_graphMenuOpen)
          Positioned(
            bottom: 72,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: _GraphType.values
                  .map((g) => _GraphPill(
                        icon: g.icon,
                        label: g.label,
                        isActive: _activeGraph == g,
                        onTap: () => setState(() {
                          _activeGraph = g;
                          _graphMenuOpen = false;
                        }),
                      ))
                  .toList(),
            ),
          ),

        // ── FAB ──────────────────────────────────────────────────────────────
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: () =>
                setState(() => _graphMenuOpen = !_graphMenuOpen),
            backgroundColor: const Color(0xFF1F2937),
            tooltip: 'Switch graph',
            child: Icon(
              _graphMenuOpen ? Icons.close : Icons.stacked_bar_chart,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stats row
  // ---------------------------------------------------------------------------

  Widget _buildStatsRow() {
    final results = _results!;
    final children = <Widget>[];

    for (int i = 0; i < results.length; i++) {
      final e = results[i];
      final color = _sessionColors[i.clamp(0, 2)];
      String stats;
      switch (_activeGraph) {
        case _GraphType.frontTravel:
          final d = e.result.frontTravel;
          stats =
              'Peak ${d.peakCenterPct.toStringAsFixed(0)}%  >80% ${d.pctAbove80.toStringAsFixed(1)}%';
        case _GraphType.rearTravel:
          final d = e.result.rearTravel;
          stats =
              'Peak ${d.peakCenterPct.toStringAsFixed(0)}%  >80% ${d.pctAbove80.toStringAsFixed(1)}%';
        case _GraphType.frontVelocity:
          final d = e.result.frontVelocity;
          stats =
              'C ${d.compressionAreaPct.toStringAsFixed(0)}%  R ${d.reboundAreaPct.toStringAsFixed(0)}%  HS-C ${d.hsCompressionPct.toStringAsFixed(1)}%';
        case _GraphType.rearVelocity:
          final d = e.result.rearVelocity;
          stats =
              'C ${d.compressionAreaPct.toStringAsFixed(0)}%  R ${d.reboundAreaPct.toStringAsFixed(0)}%  HS-C ${d.hsCompressionPct.toStringAsFixed(1)}%';
      }
      children.add(Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 7,
                height: 7,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(stats,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70)),
          ],
        ),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }

  // ---------------------------------------------------------------------------
  // Active chart
  // ---------------------------------------------------------------------------

  Widget _buildActiveChart() {
    final results = _results!;

    // Builds a [CompareSeriesData] for session at [i] using [values] as bin data.
    CompareSeriesData buildSeries(int i, List<double> values) =>
        CompareSeriesData(
          label: results[i].sessionName,
          color: _sessionColors[i.clamp(0, 2)],
          values: values,
        );

    switch (_activeGraph) {
      case _GraphType.frontTravel:
        final bins = results.first.result.frontTravel.centersPct;
        return CompareHistogramChart(
          binCenters: bins,
          series: List.generate(results.length,
              (i) => buildSeries(i, results[i].result.frontTravel.timePct)),
          xAxisLabel: 'Travel (%)',
          yAxisLabel: 'Time (%)',
          referenceLines: _travelReferenceLines(),
        );

      case _GraphType.rearTravel:
        final bins = results.first.result.rearTravel.centersPct;
        return CompareHistogramChart(
          binCenters: bins,
          series: List.generate(results.length,
              (i) => buildSeries(i, results[i].result.rearTravel.timePct)),
          xAxisLabel: 'Travel (%)',
          yAxisLabel: 'Time (%)',
          referenceLines: _travelReferenceLines(),
        );

      case _GraphType.frontVelocity:
        final bins = results.first.result.frontVelocity.centersMmS;
        return CompareHistogramChart(
          binCenters: bins,
          series: List.generate(
              results.length,
              (i) =>
                  buildSeries(i, results[i].result.frontVelocity.timePct)),
          xAxisLabel: 'Velocity (mm/s)',
          yAxisLabel: 'Time (%)',
          referenceLines: _velocityReferenceLines(),
        );

      case _GraphType.rearVelocity:
        final bins = results.first.result.rearVelocity.centersMmS;
        return CompareHistogramChart(
          binCenters: bins,
          series: List.generate(
              results.length,
              (i) =>
                  buildSeries(i, results[i].result.rearVelocity.timePct)),
          xAxisLabel: 'Velocity (mm/s)',
          yAxisLabel: 'Time (%)',
          referenceLines: _velocityReferenceLines(),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Reference lines
  // ---------------------------------------------------------------------------

  List<VerticalLine> _travelReferenceLines() => [
        VerticalLine(
          x: 30,
          color: Colors.green,
          strokeWidth: 1.5,
          dashArray: [4, 4],
          label: VerticalLineLabel(
            show: true,
            labelResolver: (_) => 'Sag',
            style: const TextStyle(fontSize: 9, color: Colors.green),
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
      ];

  List<VerticalLine> _velocityReferenceLines() {
    const ls = 150.0;
    return [
      VerticalLine(x: 0, color: Colors.grey, strokeWidth: 1.2),
      VerticalLine(
        x: ls,
        color: Colors.blue,
        strokeWidth: 1,
        dashArray: [4, 4],
        label: VerticalLineLabel(
          show: true,
          labelResolver: (_) => 'LS|HS',
          style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
        ),
      ),
      VerticalLine(
        x: -ls,
        color: Colors.blue,
        strokeWidth: 1,
        dashArray: [4, 4],
        label: VerticalLineLabel(
          show: true,
          labelResolver: (_) => 'LS|HS',
          style: const TextStyle(fontSize: 8, color: Color(0xFF6B7280)),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Floating graph-type pill button
// ---------------------------------------------------------------------------

class _GraphPill extends StatelessWidget {
  const _GraphPill({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFF97316)
                : Colors.grey.shade900,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
