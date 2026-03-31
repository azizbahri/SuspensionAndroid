import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/analysis_result.dart';
import '../../../domain/entities/session.dart';
import '../../providers/providers.dart';
import '../../widgets/diagnostic_card.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/travel_histogram_chart.dart';
import '../../widgets/velocity_histogram_chart.dart';

/// Compare up to 3 analyzed sessions side-by-side.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key});

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  final _selectedIds = <String>{};
  bool _comparing = false;
  String? _error;
  List<SessionCompareEntry>? _results;

  Future<void> _compare() async {
    setState(() {
      _comparing = true;
      _error = null;
    });

    final result = await ref
        .read(compareSessionsUseCaseProvider)(_selectedIds.toList());

    setState(() => _comparing = false);

    result.fold(
      onSuccess: (r) => setState(() => _results = r.sessions),
      onFailure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Compare Sessions')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorBanner(message: e.toString()),
        data: (sessions) => _buildBody(sessions),
      ),
    );
  }

  Widget _buildBody(List<Session> sessions) {
    final analyzed = sessions.where((s) => s.analyzed).toList();

    if (analyzed.isEmpty) {
      return const Center(
        child: Text('No analyzed sessions available.\n'
            'Import or simulate a session and analyze it first.'),
      );
    }

    const colors = [Colors.orange, Colors.blue, Colors.purple];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_error != null)
          ErrorBanner(
              message: _error!,
              onDismiss: () => setState(() => _error = null)),

        const Text('Select 2–3 sessions to compare:'),
        const SizedBox(height: 8),
        ...analyzed.asMap().entries.map((e) {
          final idx = e.key;
          final session = e.value;
          final isSelected = _selectedIds.contains(session.id);
          final isDisabled = !isSelected && _selectedIds.length >= 3;
          return CheckboxListTile(
            title: Text(session.name),
            subtitle: Text(session.bikeSlug),
            secondary: isSelected
                ? Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors[_selectedIds
                          .toList()
                          .indexOf(session.id)
                          .clamp(0, 2)],
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_selectedIds.length >= 2 && !_comparing) ? _compare : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
            ),
            child: _comparing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Compare'),
          ),
        ),

        if (_results != null) ...[
          const SizedBox(height: 24),
          _CompareResults(entries: _results!, colors: colors),
        ],
      ]),
    );
  }
}

class _CompareResults extends StatelessWidget {
  const _CompareResults(
      {required this.entries, required this.colors});
  final List<SessionCompareEntry> entries;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Front Travel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ...entries.asMap().entries.map((e) => TravelHistogramChart(
            data: e.value.result.frontTravel,
            title: e.value.sessionName,
          )),
      const SizedBox(height: 16),
      const Text('Rear Travel',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ...entries.asMap().entries.map((e) => TravelHistogramChart(
            data: e.value.result.rearTravel,
            title: e.value.sessionName,
          )),
      const SizedBox(height: 16),
      const Text('Front Velocity',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ...entries.asMap().entries.map((e) => VelocityHistogramChart(
            data: e.value.result.frontVelocity,
            title: e.value.sessionName,
          )),
      const SizedBox(height: 16),
      // Summary table
      _SummaryTable(entries: entries),
    ]);
  }
}

class _SummaryTable extends StatelessWidget {
  const _SummaryTable({required this.entries});
  final List<SessionCompareEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1),
          },
          children: [
            const TableRow(children: [
              Text('Session', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('F Peak', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('R Peak', style: TextStyle(fontWeight: FontWeight.bold)),
            ]),
            ...entries.map((e) => TableRow(children: [
                  Text(e.sessionName),
                  Text(
                      '${e.result.frontTravel.peakCenterPct.toStringAsFixed(0)}%'),
                  Text(
                      '${e.result.rearTravel.peakCenterPct.toStringAsFixed(0)}%'),
                ])),
          ],
        ),
      ),
    );
  }
}
