import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/session.dart';
import '../../providers/providers.dart';
import '../../widgets/diagnostic_card.dart';
import '../../widgets/error_banner.dart';
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

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: (sessions) => _buildBody(sessions),
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
          _ResultsSection(result: _result!),
        ],
      ]),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  const _ResultsSection({required this.result});
  final AnalysisResult result;

  @override
  Widget build(BuildContext context) {
    // Sort diagnostics: critical > warning > info
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
      TravelHistogramChart(data: result.frontTravel, title: 'Travel Distribution'),
      VelocityHistogramChart(
          data: result.frontVelocity, title: 'Velocity Distribution'),

      const SizedBox(height: 12),
      const Text('Rear Suspension',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      TravelHistogramChart(data: result.rearTravel, title: 'Travel Distribution'),
      VelocityHistogramChart(
          data: result.rearVelocity, title: 'Velocity Distribution'),

      if (sorted.isNotEmpty) ...[
        const SizedBox(height: 12),
        const Text('Diagnostics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...sorted.map((note) => DiagnosticCard(note: note)),
      ],

      // Footer
      const SizedBox(height: 12),
      _Footer(result: result),
    ]);
  }
}

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
