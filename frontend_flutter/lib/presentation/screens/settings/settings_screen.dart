import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// App settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugModeAsync = ref.watch(debugModeProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
        children: [
          const ListTile(
            title: Text('Suspension Study'),
            subtitle: Text('Version 1.0.0 — Pure Flutter, no backend'),
            leading: Icon(Icons.motorcycle),
          ),
          const Divider(),
          debugModeAsync.when(
            loading: () => const ListTile(
              title: Text('Debug Mode'),
              trailing: CircularProgressIndicator(),
            ),
            error: (_, __) => const ListTile(title: Text('Debug Mode')),
            data: (enabled) => SwitchListTile(
              title: const Text('Debug Mode'),
              subtitle: Text(
                enabled
                    ? 'Simulator tab visible — generates synthetic data'
                    : 'Simulator tab hidden (production mode)',
              ),
              value: enabled,
              activeColor: const Color(0xFFF97316),
              onChanged: (_) =>
                  ref.read(debugModeProvider.notifier).toggle(),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('Data Source'),
            subtitle: Text('USB OTG DAQ — not connected\n'
                'Use the Simulator tab to generate test data'),
            leading: Icon(Icons.usb),
          ),
          const Divider(),
          ListTile(
            title: const Text('Storage Location'),
            subtitle: const Text('App documents directory — JSON files'),
            leading: const Icon(Icons.folder),
            onTap: () {},
          ),
          const ListTile(
            title: Text('Signal Processing'),
            subtitle: Text(
              '2nd-order Butterworth LPF\n'
              'Complementary filter pitch (α = 0.98)\n'
              'All processing runs on-device in Dart',
            ),
            leading: Icon(Icons.memory),
          ),
        ],
      ),
      ),
    );
  }
}
