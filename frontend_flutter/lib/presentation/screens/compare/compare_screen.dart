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
/// Shows a single full-detail chart at a time.  A floating round button
/// opens a collapsible bottom menu for switching graph types.  The chart
/// area supports pinch-zoom and pan via [InteractiveViewer].
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
      onFailure: (e) => setState(() => _error = e.message),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Sessions')),
      floatingActionButton: _results != null ? _buildFab() : null,
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: _buildBody,
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return FloatingActionButton(
      mini: true,
      onPressed: () => setState(() => _graphMenuOpen = !_graphMenuOpen),
      backgroundColor: const Color(0xFF1F2937),
      tooltip: 'Switch graph',
      child: Icon(
        _graphMenuOpen ? Icons.close : Icons.stacked_bar_chart,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody(List<Session> sessions) {
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

        // ── Session selector ────────────────────────────────────────────────
        _buildSessionSelector(analyzed),

        // ── Compare button ──────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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

        // ── Chart area (or placeholder) ─────────────────────────────────────
        if (_results != null)
          Expanded(child: _buildChartArea())
        else
          const Expanded(
            child: Center(
              child: Text(
                'Select 2–3 sessions and press Compare',
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
          ),
      ],
    );
  }

  // ── Session selector ──────────────────────────────────────────────────────

  Widget _buildSessionSelector(List<Session> analyzed) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select 2–3 sessions to compare:',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
          ...analyzed.asMap().entries.map((e) {
            final session = e.value;
            final isSelected = _selectedIds.contains(session.id);
            final isDisabled = !isSelected && _selectedIds.length >= 3;
            final colorIndex =
                _selectedIds.toList().indexOf(session.id).clamp(0, 2);
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
                        _results = null;
                      }),
            );
          }),
        ],
      ),
    );
  }

  // ── Chart area ────────────────────────────────────────────────────────────

  Widget _buildChartArea() {
    return Column(
      children: [
        // ── Graph title + per-session stats ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _activeGraph.label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 4),
              _buildStatsRow(),
            ],
          ),
        ),

        // ── Focused chart with gesture support ──────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
            child: InteractiveViewer(
              scaleEnabled: true,
              panEnabled: true,
              minScale: 0.5,
              maxScale: 6.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: _buildActiveChart(),
            ),
          ),
        ),

        // ── Collapsible graph-type menu ──────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          height: _graphMenuOpen ? 138 : 0,
          child: _graphMenuOpen
              ? _buildGraphMenu()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  // ── Stats row (key metrics per session) ───────────────────────────────────

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
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text(stats,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: children),
    );
  }

  // ── Active chart ──────────────────────────────────────────────────────────

  Widget _buildActiveChart() {
    final results = _results!;

    CompareSeriesData _series(int i, List<double> bins, List<double> values) =>
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
              (i) => _series(i, bins, results[i].result.frontTravel.timePct)),
          xAxisLabel: 'Travel (%)',
          yAxisLabel: 'Time (%)',
          referenceLines: _travelReferenceLines(),
        );

      case _GraphType.rearTravel:
        final bins = results.first.result.rearTravel.centersPct;
        return CompareHistogramChart(
          binCenters: bins,
          series: List.generate(results.length,
              (i) => _series(i, bins, results[i].result.rearTravel.timePct)),
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
                  _series(i, bins, results[i].result.frontVelocity.timePct)),
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
                  _series(i, bins, results[i].result.rearVelocity.timePct)),
          xAxisLabel: 'Velocity (mm/s)',
          yAxisLabel: 'Time (%)',
          referenceLines: _velocityReferenceLines(),
        );
    }
  }

  // ── Reference lines ───────────────────────────────────────────────────────

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
      VerticalLine(
          x: 0,
          color: Colors.grey,
          strokeWidth: 1.2),
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

  // ── Bottom graph-type menu ────────────────────────────────────────────────

  Widget _buildGraphMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Graph options (horizontal scroll)
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _GraphType.values
                  .map((g) => Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _GraphMenuCard(
                          type: g,
                          isActive: _activeGraph == g,
                          onTap: () => setState(() {
                            _activeGraph = g;
                            _graphMenuOpen = false;
                          }),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Graph-type menu card
// ---------------------------------------------------------------------------

class _GraphMenuCard extends StatelessWidget {
  const _GraphMenuCard({
    required this.type,
    required this.isActive,
    required this.onTap,
  });

  final _GraphType type;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFF97316);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 96,
        height: 80,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.icon,
              size: 24,
              color: isActive ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(height: 6),
            Text(
              type.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
