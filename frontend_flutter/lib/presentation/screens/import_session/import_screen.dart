import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../data/hardware/data_source.dart';
import '../../../data/simulator/simulator_config.dart';
import '../../../domain/entities/column_map.dart';
import '../../../domain/entities/session.dart';
import '../../../data/processing/session_pipeline.dart';
import '../../providers/providers.dart';
import '../../widgets/bike_selector.dart';
import '../../widgets/error_banner.dart';

/// Screen for creating a new session by importing a CSV file or
/// by selecting a simulator scenario (debug mode).
class ImportScreen extends ConsumerStatefulWidget {
  const ImportScreen({super.key});

  @override
  ConsumerState<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends ConsumerState<ImportScreen> {
  final _nameController = TextEditingController();
  String? _selectedBikeSlug;
  String? _csvPath;
  VelocityQuantity _velocityQuantity = VelocityQuantity.shaft;
  ColumnMap _columnMap = const ColumnMap();
  bool _loading = false;
  String? _error;
  String? _successMessage;

  bool get _canImport =>
      _nameController.text.trim().isNotEmpty &&
      _selectedBikeSlug != null &&
      _csvPath != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _csvPath = result.files.single.path);
    }
  }

  Future<void> _import() async {
    setState(() {
      _loading = true;
      _error = null;
      _successMessage = null;
    });

    final session = Session(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      bikeSlug: _selectedBikeSlug!,
      dataSourceType: DataSourceType.csvFile,
      csvPath: _csvPath,
      columnMap: _columnMap,
      velocityQuantity: _velocityQuantity,
      createdAt: DateTime.now(),
    );

    final result =
        await ref.read(createSessionUseCaseProvider)(session);

    setState(() => _loading = false);

    result.fold(
      onSuccess: (_) =>
          setState(() => _successMessage = 'Session "${session.name}" imported successfully'),
      onFailure: (e) => setState(() => _error = e.message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikesProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_error != null)
            ErrorBanner(
              message: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
          if (_successMessage != null)
            _SuccessBanner(message: _successMessage!),

          // Session name
          const Text('Session Name'),
          const SizedBox(height: 4),
          TextField(
            key: const Key('session_name_field'),
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'e.g. Sunday practice run',
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
              key: const Key('bike_selector'),
              bikes: bikes,
              selectedSlug: _selectedBikeSlug,
              onChanged: (slug) => setState(() => _selectedBikeSlug = slug),
            ),
          ),
          const SizedBox(height: 16),

          // CSV file picker
          const Text('CSV File'),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(
              child: Text(
                _csvPath ?? 'No file selected',
                style: TextStyle(
                  color: _csvPath != null ? null : Colors.grey,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              key: const Key('pick_file_button'),
              onPressed: _pickFile,
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse'),
            ),
          ]),
          const SizedBox(height: 16),

          // Velocity quantity
          const Text('Velocity Quantity'),
          Row(children: VelocityQuantity.values.map((q) {
            return Row(mainAxisSize: MainAxisSize.min, children: [
              Radio<VelocityQuantity>(
                value: q,
                groupValue: _velocityQuantity,
                onChanged: (v) => setState(() => _velocityQuantity = v!),
              ),
              Text(q.name),
              const SizedBox(width: 8),
            ]);
          }).toList()),
          const SizedBox(height: 16),

          // Column mapping (collapsible)
          _ColumnMapSection(
            columnMap: _columnMap,
            onChanged: (cm) => setState(() => _columnMap = cm),
          ),
          const SizedBox(height: 24),

          // Import button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (!_loading && _canImport) ? _import : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Import Session'),
            ),
          ),
        ]),
        ),
      ),
    );
  }
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
        child: Text(message,
            style: TextStyle(color: Colors.green.shade800)),
      );
}

class _ColumnMapSection extends StatefulWidget {
  const _ColumnMapSection({required this.columnMap, required this.onChanged});
  final ColumnMap columnMap;
  final ValueChanged<ColumnMap> onChanged;

  @override
  State<_ColumnMapSection> createState() => _ColumnMapSectionState();
}

class _ColumnMapSectionState extends State<_ColumnMapSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('Column Mapping (advanced)'),
      initiallyExpanded: false,
      onExpansionChanged: (v) => setState(() => _expanded = v),
      children: [
        _colField('Front Raw Column', widget.columnMap.frontRawCol,
            (v) => widget.onChanged(widget.columnMap.copyWith(frontRawCol: v))),
        _colField('Rear Raw Column', widget.columnMap.rearRawCol,
            (v) => widget.onChanged(widget.columnMap.copyWith(rearRawCol: v))),
        _colField('Gyro Y Column', widget.columnMap.gyroYCol,
            (v) => widget.onChanged(widget.columnMap.copyWith(gyroYCol: v))),
        _colField('Accel X Column', widget.columnMap.accelXCol,
            (v) => widget.onChanged(widget.columnMap.copyWith(accelXCol: v))),
        CheckboxListTile(
          title: const Text('Invert Front'),
          value: widget.columnMap.invertFront,
          onChanged: (v) => widget.onChanged(
              widget.columnMap.copyWith(invertFront: v ?? false)),
        ),
        CheckboxListTile(
          title: const Text('Invert Rear'),
          value: widget.columnMap.invertRear,
          onChanged: (v) => widget.onChanged(
              widget.columnMap.copyWith(invertRear: v ?? false)),
        ),
      ],
    );
  }

  Widget _colField(
      String label, String initial, ValueChanged<String> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        initialValue: initial,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}
