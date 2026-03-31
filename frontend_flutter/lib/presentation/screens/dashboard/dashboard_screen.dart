import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/providers.dart';

/// Dashboard / home screen.
///
/// Mirrors the React DashboardPage: hero card, stats row, and workflow
/// step cards that navigate to the corresponding screens.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final bikesAsync = ref.watch(bikesProvider);

    final sessionCount = sessionsAsync.valueOrNull?.length ?? 0;
    final bikeCount = bikesAsync.valueOrNull?.length ?? 0;
    final analyzedCount = sessionsAsync.valueOrNull
            ?.where((s) => s.analyzed)
            .length ??
        0;

    return Scaffold(
      appBar: AppBar(title: const Text('Suspension Study')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Hero ──────────────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF1F2937)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.motorcycle,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Suspension Study',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'Motorcycle suspension DAQ post-processor — '
                          'import a ride CSV, calibrate sensor transfer '
                          'functions, and get data-driven tuning advice '
                          'from travel and velocity histograms.',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Stats ─────────────────────────────────────────────────────
            Row(
              children: [
                _StatCard(label: 'Sessions', value: '$sessionCount'),
                const SizedBox(width: 8),
                _StatCard(label: 'Bike profiles', value: '$bikeCount'),
                const SizedBox(width: 8),
                _StatCard(label: 'Analyzed', value: '$analyzedCount'),
              ],
            ),
            const SizedBox(height: 16),

            // ── Workflow steps ────────────────────────────────────────────
            _WorkflowCard(
              icon: Icons.upload_file,
              title: 'Import',
              description:
                  'Register a DAQ CSV file and map its columns to the '
                  'signal names the pipeline expects.',
              onTap: () => context.go('/import'),
            ),
            _WorkflowCard(
              icon: Icons.tune,
              title: 'Calibrate',
              description:
                  'Fit your sensor transfer functions and linkage '
                  'polynomial, then apply them to a bike profile.',
              onTap: () => context.go('/calibrate'),
            ),
            _WorkflowCard(
              icon: Icons.bar_chart,
              title: 'Analyze',
              description:
                  'Run the full signal processing pipeline and view '
                  'travel histograms, velocity histograms, and pitch trace.',
              onTap: () => context.go('/analyze'),
            ),
            _WorkflowCard(
              icon: Icons.compare_arrows,
              title: 'Compare',
              description:
                  'Overlay up to three sessions side-by-side to evaluate '
                  'setup changes between rides.',
              onTap: () => context.go('/compare'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: Icon(icon, color: const Color(0xFFF97316)),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(description,
              style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
}
