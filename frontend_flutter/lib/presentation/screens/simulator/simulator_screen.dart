import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../data/hardware/data_source.dart';
import '../../../data/simulator/simulator_config.dart';
import '../../../domain/entities/session.dart';
import '../../../data/processing/session_pipeline.dart';
import '../../providers/providers.dart';
import '../../widgets/bike_selector.dart';
import '../../widgets/error_banner.dart';

/// Debug Simulator screen — lets developers configure and run any scenario
/// without physical hardware, producing a session that can then be analyzed.
///
/// Mirrors the Python daq-simulate CLI tool as a configurable in-app UI.
class SimulatorScreen extends ConsumerStatefulWidget {
  const SimulatorScreen({super.key});

  @override
  ConsumerState<SimulatorScreen> createState() => _SimulatorScreenState();
}

class _SimulatorScreenState extends ConsumerState<SimulatorScreen> {
  SimulatorConfig _config = const SimulatorConfig();
  String? _selectedBikeSlug;
  final _nameController = TextEditingController();
  bool _running = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    if (_selectedBikeSlug == null) {
      setState(() => _error = 'Select a bike profile first');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a session name');
      return;
    }

    setState(() {
      _running = true;
      _error = null;
      _success = null;
    });

    final session = Session(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      bikeSlug: _selectedBikeSlug!,
      dataSourceType: DataSourceType.simulator,
      simulatorConfig: _config,
      velocityQuantity: VelocityQuantity.shaft,
      createdAt: DateTime.now(),
    );

    final result = await ref.read(createSessionUseCaseProvider)(session);
    setState(() => _running = false);

    result.fold(
      onSuccess: (_) => setState(() =>
          _success = 'Simulation session "${session.name}" created. Go to Analyze to process it.'),
      onFailure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Simulator'),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.orange),
            ),
            child: const Text('DEBUG',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null)
            ErrorBanner(
              message: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          if (_success != null)
            _SuccessBanner(message: _success!),

          // Session name
          const Text('Session Name'),
          const SizedBox(height: 4),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'e.g. Sim — Rough Terrain',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Bike selector
          const Text('Bike Profile'),
          const SizedBox(height: 4),
          bikesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ErrorBanner(message: e.toString()),
            data: (bikes) => BikeSelector(
              bikes: bikes,
              selectedSlug: _selectedBikeSlug,
              onChanged: (slug) => setState(() => _selectedBikeSlug = slug),
            ),
          ),
          const SizedBox(height: 16),

          // Scenario selector
          const Text('Scenario'),
          const SizedBox(height: 4),
          DropdownButtonFormField<SimulatorScenario>(
            value: _config.scenario,
            decoration: const InputDecoration(
                border: OutlineInputBorder(), isDense: true),
            items: SimulatorScenario.values
                .map((s) => DropdownMenuItem(
                    value: s, child: Text(s.label)))
                .toList(),
            onChanged: (s) =>
                setState(() => _config = _config.copyWith(scenario: s)),
          ),
          const SizedBox(height: 16),

          // Duration slider
          _SliderRow(
            label: 'Duration',
            value: _config.durationS,
            min: 2,
            max: 60,
            divisions: 58,
            displayText: '${_config.durationS.toStringAsFixed(0)} s',
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(durationS: v)),
          ),

          // Noise toggle
          SwitchListTile(
            title: const Text('Enable Gaussian noise'),
            subtitle: const Text('Simulates realistic ADC + IMU noise'),
            value: _config.enableNoise,
            activeColor: const Color(0xFFF97316),
            onChanged: (v) =>
                setState(() => _config = _config.copyWith(enableNoise: v)),
            contentPadding: EdgeInsets.zero,
          ),

          if (_config.enableNoise) ...[
            _SliderRow(
              label: 'Front ADC noise',
              value: _config.frontNoiseRms,
              min: 0,
              max: 5,
              divisions: 50,
              displayText: '${_config.frontNoiseRms.toStringAsFixed(1)} LSB',
              onChanged: (v) => setState(
                  () => _config = _config.copyWith(frontNoiseRms: v)),
            ),
            _SliderRow(
              label: 'Rear ADC noise',
              value: _config.rearNoiseRms,
              min: 0,
              max: 5,
              divisions: 50,
              displayText: '${_config.rearNoiseRms.toStringAsFixed(1)} LSB',
              onChanged: (v) => setState(
                  () => _config = _config.copyWith(rearNoiseRms: v)),
            ),
            _SliderRow(
              label: 'Gyro bias',
              value: _config.gyroBiasDegS,
              min: 0,
              max: 1,
              divisions: 100,
              displayText: '${_config.gyroBiasDegS.toStringAsFixed(2)} °/s',
              onChanged: (v) => setState(
                  () => _config = _config.copyWith(gyroBiasDegS: v)),
            ),
          ],

          // Random seed
          const SizedBox(height: 8),
          Row(children: [
            const Text('Random seed: '),
            Text('${_config.seed}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => setState(() => _config =
                  _config.copyWith(seed: DateTime.now().millisecondsSinceEpoch % 1000)),
              child: const Text('Randomize'),
            ),
          ]),
          const SizedBox(height: 24),

          // Run button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _running ? null : _runSimulation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
              ),
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.play_arrow),
              label: Text(_running ? 'Generating…' : 'Create Simulation Session'),
            ),
          ),
        ]),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayText,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayText;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(displayText,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: const Color(0xFFF97316),
            onChanged: onChanged,
          ),
        ],
      );
}

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(message, style: TextStyle(color: Colors.green.shade800)),
      );
}
