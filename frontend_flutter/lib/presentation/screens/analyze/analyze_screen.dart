import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/session.dart';
import '../../providers/providers.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pitch_chart.dart';
import '../../widgets/travel_histogram_chart.dart';
import '../../widgets/velocity_histogram_chart.dart';

// ---------------------------------------------------------------------------
// Graph-type enum
// ---------------------------------------------------------------------------

enum _AnalyzeGraph {
  frontTravel,
  rearTravel,
  frontVelocity,
  rearVelocity,
  pitch;

  String get label => switch (this) {
        frontTravel => 'Front Travel',
        rearTravel => 'Rear Travel',
        frontVelocity => 'Front Velocity',
        rearVelocity => 'Rear Velocity',
        pitch => 'Pitch & Accel',
      };

  IconData get icon => switch (this) {
        frontTravel || rearTravel => Icons.stacked_bar_chart,
        frontVelocity || rearVelocity => Icons.speed,
        pitch => Icons.show_chart,
      };
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Analyze a single session and display full-screen charts.
///
/// Two modes:
///  - **Selector view** (no result yet): session dropdown + Analyze button.
///  - **Chart view** (result available): single full-screen chart in an
///    [InteractiveViewer] (pinch-zoom + pan).  A floating mini FAB expands
///    upward into pill-shaped graph-type buttons (5 types).
class AnalyzeScreen extends ConsumerStatefulWidget {
  const AnalyzeScreen({super.key, this.preselectedSessionId});

  final String? preselectedSessionId;

  @override
  ConsumerState<AnalyzeScreen> createState() => _AnalyzeScreenState();
}

class _AnalyzeScreenState extends ConsumerState<AnalyzeScreen> {
  String? _selectedSessionId;
  bool _analyzing = false;
  String? _error;
  AnalysisResult? _result;

  _AnalyzeGraph _activeGraph = _AnalyzeGraph.frontTravel;
  bool _graphMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.preselectedSessionId;
  }

  Session? _findSession(List<Session> sessions) =>
      _selectedSessionId == null
          ? null
          : sessions.where((s) => s.id == _selectedSessionId).firstOrNull;

  Future<void> _analyze(Session session) async {
    setState(() {
      _analyzing = true;
      _error = null;
    });

    final result =
        await ref.read(analyzeSessionUseCaseProvider)(session);

    setState(() => _analyzing = false);

    result.fold(
      onSuccess: (r) {
        setState(() => _result = r);
        ref.invalidate(sessionsProvider);
      },
      onFailure: (e) => setState(() {
        _error = e.message;
        _result = null;
      }),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      body: SafeArea(
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorBanner(message: e.toString()),
          data: _buildBody,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Body router
  // ---------------------------------------------------------------------------

  Widget _buildBody(List<Session> sessions) {
    if (_result != null) return _buildChartView();
    return _buildSelectorView(sessions);
  }

  // ---------------------------------------------------------------------------
  // Selector view
  // ---------------------------------------------------------------------------

  Widget _buildSelectorView(List<Session> sessions) {
    final session = _findSession(sessions);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null)
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),

        // Session dropdown
        const Text('Session',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          key: const Key('session_dropdown'),
          value: _selectedSessionId,
          hint: const Text('Select session…'),
          decoration: const InputDecoration(
              border: OutlineInputBorder(), isDense: true),
          items: sessions
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.name} ${s.analyzed ? "✓" : ""}',
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (id) => setState(() {
            _selectedSessionId = id;
            _result = null;
          }),
        ),
        const SizedBox(height: 12),

        // Analyze button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (!_analyzing && session != null)
                ? () => _analyze(session)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
            ),
            child: _analyzing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Analyze / Re-analyze'),
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------------------
  // Full-screen chart view
  // ---------------------------------------------------------------------------

  // Height (px) of the stats overlay bar at the top of the chart view.
  // Matches the top padding (44) + bottom padding (8) applied around the chart.
  static const _chartPaddingTotal = 52.0;

  Widget _buildChartView() {
    return Stack(
      children: [
        // ── Full-screen chart (fixed, fills screen) ───────────────────────────
        Positioned.fill(
          child: LayoutBuilder(
            builder: (ctx, c) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 44, 8, 8),
              child: _buildActiveChart(c.maxHeight - _chartPaddingTotal),
            ),
          ),
        ),

        // ── Stats overlay (semi-transparent top bar) ──────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.55),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(children: [
              // Back to session selector
              GestureDetector(
                onTap: () => setState(() {
                  _result = null;
                  _graphMenuOpen = false;
                }),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 14, color: Colors.white70),
              ),
              const SizedBox(width: 8),
              Text(
                _activeGraph.label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _buildStatsString(),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.white70),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
        ),

        // ── Backdrop — closes menu when tapping elsewhere ──────────────────────
        if (_graphMenuOpen)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => _graphMenuOpen = false),
              child: const ColoredBox(color: Color(0x44000000)),
            ),
          ),

        // ── Floating graph-type menu (grows upward from FAB) ──────────────────
        if (_graphMenuOpen)
          Positioned(
            bottom: 72,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: _AnalyzeGraph.values
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

        // ── FAB ───────────────────────────────────────────────────────────────
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
  // Stats string for overlay
  // ---------------------------------------------------------------------------

  String _buildStatsString() {
    final r = _result!;
    return switch (_activeGraph) {
      _AnalyzeGraph.frontTravel => () {
          final d = r.frontTravel;
          return 'Peak: ${d.peakCenterPct.toStringAsFixed(1)}%'
              '   >80%: ${d.pctAbove80.toStringAsFixed(1)}%';
        }(),
      _AnalyzeGraph.rearTravel => () {
          final d = r.rearTravel;
          return 'Peak: ${d.peakCenterPct.toStringAsFixed(1)}%'
              '   >80%: ${d.pctAbove80.toStringAsFixed(1)}%';
        }(),
      _AnalyzeGraph.frontVelocity => () {
          final d = r.frontVelocity;
          return 'C: ${d.compressionAreaPct.toStringAsFixed(0)}%'
              '  R: ${d.reboundAreaPct.toStringAsFixed(0)}%'
              '  LS-C: ${d.lsCompressionPct.toStringAsFixed(1)}%'
              '  HS-C: ${d.hsCompressionPct.toStringAsFixed(1)}%'
              '  LS-R: ${d.lsReboundPct.toStringAsFixed(1)}%'
              '  HS-R: ${d.hsReboundPct.toStringAsFixed(1)}%';
        }(),
      _AnalyzeGraph.rearVelocity => () {
          final d = r.rearVelocity;
          return 'C: ${d.compressionAreaPct.toStringAsFixed(0)}%'
              '  R: ${d.reboundAreaPct.toStringAsFixed(0)}%'
              '  LS-C: ${d.lsCompressionPct.toStringAsFixed(1)}%'
              '  HS-C: ${d.hsCompressionPct.toStringAsFixed(1)}%'
              '  LS-R: ${d.lsReboundPct.toStringAsFixed(1)}%'
              '  HS-R: ${d.hsReboundPct.toStringAsFixed(1)}%';
        }(),
      _AnalyzeGraph.pitch => () {
          final d = r.pitch;
          if (d.pitchDeg.isEmpty) return '';
          final maxP = d.pitchDeg.reduce((a, b) => a > b ? a : b);
          final minP = d.pitchDeg.reduce((a, b) => a < b ? a : b);
          final maxA = d.accelXG.reduce((a, b) => a > b ? a : b);
          final minA = d.accelXG.reduce((a, b) => a < b ? a : b);
          return 'Max pitch: ${maxP.toStringAsFixed(1)}°'
              '  Min: ${minP.toStringAsFixed(1)}°'
              '  Peak accel: ${maxA.toStringAsFixed(2)} g'
              '  Min: ${minA.toStringAsFixed(2)} g';
        }(),
    };
  }

  // ---------------------------------------------------------------------------
  // Active chart — height-aware so it fills the screen
  // ---------------------------------------------------------------------------

  Widget _buildActiveChart(double availableHeight) {
    // Card vertical padding (16 top + 16 bottom) = 32 px.
    // Stats row (~24 px) + SizedBox(8) above chart = 32 px overhead.
    // When title is '' those are not rendered; net overhead ≈ 64 px.
    const histogramOverhead = 64.0;
    // Pitch: Card padding (32) + spacing between sub-charts (8) = 40 px.
    const pitchOverhead = 40.0;

    final r = _result!;
    return switch (_activeGraph) {
      _AnalyzeGraph.frontTravel => TravelHistogramChart(
          data: r.frontTravel,
          title: '',
          chartHeight: (availableHeight - histogramOverhead).clamp(100.0, double.infinity),
        ),
      _AnalyzeGraph.rearTravel => TravelHistogramChart(
          data: r.rearTravel,
          title: '',
          chartHeight: (availableHeight - histogramOverhead).clamp(100.0, double.infinity),
        ),
      _AnalyzeGraph.frontVelocity => VelocityHistogramChart(
          data: r.frontVelocity,
          title: '',
          chartHeight: (availableHeight - histogramOverhead).clamp(100.0, double.infinity),
        ),
      _AnalyzeGraph.rearVelocity => VelocityHistogramChart(
          data: r.rearVelocity,
          title: '',
          chartHeight: (availableHeight - histogramOverhead).clamp(100.0, double.infinity),
        ),
      _AnalyzeGraph.pitch => PitchChart(
          data: r.pitch,
          title: '',
          subChartHeight:
              ((availableHeight - pitchOverhead) / 2).clamp(60.0, double.infinity),
        ),
    };
  }
}

// ---------------------------------------------------------------------------
// Floating graph-type pill button (shared style with compare screen)
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

