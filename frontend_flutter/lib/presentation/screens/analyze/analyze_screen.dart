import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/session.dart';
import '../../providers/providers.dart';
import '../../widgets/chart_detail_panel.dart';
import '../../widgets/diagnostic_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/pitch_chart.dart';
import '../../widgets/travel_histogram_chart.dart';
import '../../widgets/velocity_histogram_chart.dart';

/// Screen for analyzing a session and displaying results.
///
/// Supports preselection via URL parameter ?session=<id>.
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

  /// Which chart is currently selected (drives the detail panel).
  ChartKey? _selectedChart;

  @override
  void initState() {
    super.initState();
    _selectedSessionId = widget.preselectedSessionId;
  }

  Session? _findSession(List<Session> sessions) =>
      _selectedSessionId == null
          ? null
          : sessions
              .where((s) => s.id == _selectedSessionId)
              .firstOrNull;

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
      onFailure: (e) => setState(() => _error = e.message),
    );
  }

  void _toggleChart(ChartKey key) {
    setState(() => _selectedChart = _selectedChart == key ? null : key);
  }

  void _closePanel() => setState(() => _selectedChart = null);

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final showPanel = _selectedChart != null && _result != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: (sessions) => Stack(
          children: [
            // ── Main scrollable content ───────────────────────────────────
            Positioned.fill(
              child: _buildBody(sessions),
            ),

            // ── Backdrop: tap outside panel to close ──────────────────────
            if (showPanel)
              Positioned.fill(
                child: GestureDetector(
                  onTap: _closePanel,
                  behavior: HitTestBehavior.opaque,
                  child: const ColoredBox(color: Color(0x33000000)),
                ),
              ),

            // ── Sliding detail panel from the right ────────────────────────
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              top: 0,
              bottom: 0,
              right: showPanel ? 0 : -340,
              width: 320,
              child: showPanel
                  ? ChartDetailPanel(
                      key: ValueKey(_selectedChart),
                      chartKey: _selectedChart!,
                      result: _result!,
                      onClose: _closePanel,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(List<Session> sessions) {
    final session = _findSession(sessions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null)
          ErrorBanner(
            message: _error!,
            onDismiss: () => setState(() => _error = null),
          ),

        // Session selector
        const Text('Session'),
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
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (id) => setState(() {
            _selectedSessionId = id;
            _result = null;
            _selectedChart = null;
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

        // Results
        if (_result != null) ...[
          const SizedBox(height: 16),
          _ResultsSection(
            result: _result!,
            selectedChart: _selectedChart,
            onChartTap: _toggleChart,
          ),
        ],
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Results section
// ---------------------------------------------------------------------------

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({
    required this.result,
    required this.selectedChart,
    required this.onChartTap,
  });

  final AnalysisResult result;
  final ChartKey? selectedChart;
  final ValueChanged<ChartKey> onChartTap;

  @override
  Widget build(BuildContext context) {
    final sorted = [...result.diagnostics]..sort((a, b) {
        const order = {
          DiagnosticSeverity.critical: 0,
          DiagnosticSeverity.warning: 1,
          DiagnosticSeverity.info: 2,
        };
        return order[a.severity]!.compareTo(order[b.severity]!);
      });

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Front Suspension',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      _tappableChart(
        ChartKey.frontTravel,
        TravelHistogramChart(
            data: result.frontTravel, title: 'Travel Distribution'),
      ),
      _tappableChart(
        ChartKey.frontVelocity,
        VelocityHistogramChart(
            data: result.frontVelocity, title: 'Velocity Distribution'),
      ),

      const SizedBox(height: 12),
      const Text('Rear Suspension',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      _tappableChart(
        ChartKey.rearTravel,
        TravelHistogramChart(
            data: result.rearTravel, title: 'Travel Distribution'),
      ),
      _tappableChart(
        ChartKey.rearVelocity,
        VelocityHistogramChart(
            data: result.rearVelocity, title: 'Velocity Distribution'),
      ),

      const SizedBox(height: 12),
      _tappableChart(
        ChartKey.pitch,
        PitchChart(
          data: result.pitch,
          title: 'Pitch & Acceleration Trace',
        ),
      ),

      if (sorted.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Diagnostics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...sorted.map((note) => DiagnosticCard(note: note)),
      ],

      const SizedBox(height: 12),
      _Footer(result: result),
    ]);
  }

  Widget _tappableChart(ChartKey key, Widget chart) {
    final isSelected = selectedChart == key;
    return GestureDetector(
      onTap: () => onChartTap(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF97316)
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            chart,
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: 'Tap for chart details',
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isSelected
                      ? const Color(0xFFF97316)
                      : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Footer
// ---------------------------------------------------------------------------

class _Footer extends StatelessWidget {
  const _Footer({required this.result});
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Duration: ${result.durationS.toStringAsFixed(1)} s',
                style: const TextStyle(fontSize: 12)),
            Text('Samples: ${result.sampleCount}',
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
}

