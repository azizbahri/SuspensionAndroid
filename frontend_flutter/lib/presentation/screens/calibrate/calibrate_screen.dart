import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/processing/calibration_fitter.dart';
import '../../../domain/entities/bike_profile.dart';
import '../../providers/providers.dart';
import '../../widgets/bike_selector.dart';
import '../../widgets/error_banner.dart';

/// Calibration screen — front fork linear fit + rear linkage quadratic fit
/// + bike profile CRUD. Mirrors the React CalibratePage.
class CalibrateScreen extends ConsumerStatefulWidget {
  const CalibrateScreen({super.key});

  @override
  ConsumerState<CalibrateScreen> createState() => _CalibrateScreenState();
}

class _CalibrateScreenState extends ConsumerState<CalibrateScreen> {
  String? _selectedSlug;
  FrontCalibrationResult? _frontResult;
  RearCalibrationResult? _rearResult;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final bikesAsync = ref.watch(bikesProvider);

    return Scaffold(
      body: SafeArea(
        child: bikesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorBanner(message: e.toString()),
          data: (bikes) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null)
                ErrorBanner(
                    message: _error!,
                    onDismiss: () => setState(() => _error = null)),

              // Bike selector
              const Text('Active Bike Profile'),
              const SizedBox(height: 4),
              BikeSelector(
                bikes: bikes,
                selectedSlug: _selectedSlug,
                onChanged: (s) => setState(() => _selectedSlug = s),
              ),
              const SizedBox(height: 24),

              // Front calibration
              _FrontCalibrationPanel(
                selectedSlug: _selectedSlug,
                onResult: (r) => setState(() => _frontResult = r),
                onApply: _frontResult == null
                    ? null
                    : () => _applyFront(_frontResult!),
                result: _frontResult,
              ),
              const SizedBox(height: 24),

              // Rear calibration
              _RearCalibrationPanel(
                selectedSlug: _selectedSlug,
                onResult: (r) => setState(() => _rearResult = r),
                onApply: _rearResult == null
                    ? null
                    : () => _applyRear(_rearResult!),
                result: _rearResult,
              ),
              const SizedBox(height: 24),

              // Bike profile manager
              _BikeProfileManager(bikes: bikes),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _applyFront(FrontCalibrationResult r) async {
    if (_selectedSlug == null) return;
    final bikes = ref.read(bikesProvider).valueOrNull ?? [];
    final bike = bikes.where((b) => b.slug == _selectedSlug).firstOrNull;
    if (bike == null) return;
    await ref
        .read(bikesProvider.notifier)
      .updateBike(_selectedSlug!, bike.copyWith(cFront: r.cCal, v0Front: r.v0));
  }

  Future<void> _applyRear(RearCalibrationResult r) async {
    if (_selectedSlug == null) return;
    final bikes = ref.read(bikesProvider).valueOrNull ?? [];
    final bike = bikes.where((b) => b.slug == _selectedSlug).firstOrNull;
    if (bike == null) return;
    await ref.read(bikesProvider.notifier).updateBike(
        _selectedSlug!,
        bike.copyWith(
            linkageA: r.a, linkageB: r.b, linkageC: r.c));
  }
}

class _FrontCalibrationPanel extends ConsumerStatefulWidget {
  const _FrontCalibrationPanel({
    required this.selectedSlug,
    required this.onResult,
    required this.onApply,
    required this.result,
  });
  final String? selectedSlug;
  final ValueChanged<FrontCalibrationResult> onResult;
  final VoidCallback? onApply;
  final FrontCalibrationResult? result;

  @override
  ConsumerState<_FrontCalibrationPanel> createState() =>
      _FrontCalibrationPanelState();
}

class _FrontCalibrationPanelState
    extends ConsumerState<_FrontCalibrationPanel> {
  final _rows = <({double stroke, double voltage})>[
    (stroke: 0.0, voltage: 0.5),
    (stroke: 100.0, voltage: 2.9),
  ];

  Future<void> _fit() async {
    final strokes = _rows.map((r) => r.stroke).toList();
    final voltages = _rows.map((r) => r.voltage).toList();
    final result = await ref.read(calibrateFrontUseCaseProvider)(
        strokesMm: strokes, voltagesV: voltages);
    result.fold(
      onSuccess: widget.onResult,
      onFailure: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Front Fork Calibration',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ..._rows.asMap().entries.map((e) => _CalibrationRow(
              index: e.key,
              strokeLabel: 'Stroke (mm)',
              voltageLabel: 'Voltage (V)',
              stroke: e.value.stroke,
              voltage: e.value.voltage,
              onChanged: (s, v) => setState(() {
                _rows[e.key] = (stroke: s, voltage: v);
              }),
            )),
        TextButton.icon(
          onPressed: () => setState(() {
            _rows.add((stroke: 0.0, voltage: 0.0));
          }),
          icon: const Icon(Icons.add),
          label: const Text('Add row'),
        ),
        Row(children: [
          ElevatedButton(
            onPressed: _rows.length >= 2 ? _fit : null,
            child: const Text('Fit'),
          ),
          const SizedBox(width: 8),
          if (widget.result != null)
            OutlinedButton(
              onPressed: widget.onApply,
              child: const Text('Apply to bike'),
            ),
        ]),
        if (widget.result != null) ...[
          const SizedBox(height: 8),
          _ResultCard(
            items: {
              'C_cal': '${widget.result!.cCal.toStringAsFixed(2)} mm/V',
              'V0': '${widget.result!.v0.toStringAsFixed(3)} V',
              'RMSE': '${widget.result!.rmseMm.toStringAsFixed(3)} mm',
            },
          ),
        ],
      ],
    );
  }
}

class _RearCalibrationPanel extends ConsumerStatefulWidget {
  const _RearCalibrationPanel({
    required this.selectedSlug,
    required this.onResult,
    required this.onApply,
    required this.result,
  });
  final String? selectedSlug;
  final ValueChanged<RearCalibrationResult> onResult;
  final VoidCallback? onApply;
  final RearCalibrationResult? result;

  @override
  ConsumerState<_RearCalibrationPanel> createState() =>
      _RearCalibrationPanelState();
}

class _RearCalibrationPanelState
    extends ConsumerState<_RearCalibrationPanel> {
  final _rows = <({double stroke, double travel})>[
    (stroke: 0.0, travel: 0.0),
    (stroke: 30.0, travel: 80.0),
    (stroke: 60.0, travel: 210.0),
  ];

  Future<void> _fit() async {
    final strokes = _rows.map((r) => r.stroke).toList();
    final travels = _rows.map((r) => r.travel).toList();
    final result = await ref.read(calibrateRearUseCaseProvider)(
        shockStrokesMm: strokes, wheelTravelsMm: travels);
    result.fold(
      onSuccess: widget.onResult,
      onFailure: (e) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Rear Linkage Calibration',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 8),
        ..._rows.asMap().entries.map((e) => _CalibrationRow(
              index: e.key,
              strokeLabel: 'Shock stroke (mm)',
              voltageLabel: 'Wheel travel (mm)',
              stroke: e.value.stroke,
              voltage: e.value.travel,
              onChanged: (s, v) =>
                  setState(() => _rows[e.key] = (stroke: s, travel: v)),
            )),
        TextButton.icon(
          onPressed: () => setState(
              () => _rows.add((stroke: 0.0, travel: 0.0))),
          icon: const Icon(Icons.add),
          label: const Text('Add row'),
        ),
        Row(children: [
          ElevatedButton(
            onPressed: _rows.length >= 3 ? _fit : null,
            child: const Text('Fit'),
          ),
          const SizedBox(width: 8),
          if (widget.result != null)
            OutlinedButton(
              onPressed: widget.onApply,
              child: const Text('Apply to bike'),
            ),
        ]),
        if (widget.result != null) ...[
          const SizedBox(height: 8),
          _ResultCard(items: {
            'a': widget.result!.a.toStringAsFixed(4),
            'b': widget.result!.b.toStringAsFixed(3),
            'c': widget.result!.c.toStringAsFixed(3),
            'RMSE': '${widget.result!.rmseMm.toStringAsFixed(3)} mm',
          }),
        ],
      ],
    );
  }
}

class _CalibrationRow extends StatelessWidget {
  const _CalibrationRow({
    required this.index,
    required this.strokeLabel,
    required this.voltageLabel,
    required this.stroke,
    required this.voltage,
    required this.onChanged,
  });
  final int index;
  final String strokeLabel;
  final String voltageLabel;
  final double stroke;
  final double voltage;
  final void Function(double stroke, double voltage) onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(
            child: TextFormField(
              initialValue: stroke.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: strokeLabel,
                  border: const OutlineInputBorder(),
                  isDense: true),
              onChanged: (v) => onChanged(double.tryParse(v) ?? stroke, voltage),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              initialValue: voltage.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                  labelText: voltageLabel,
                  border: const OutlineInputBorder(),
                  isDense: true),
              onChanged: (v) => onChanged(stroke, double.tryParse(v) ?? voltage),
            ),
          ),
        ]),
      );
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.items});
  final Map<String, String> items;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Wrap(
          spacing: 16,
          children: items.entries
              .map((e) => Text('${e.key}: ${e.value}',
                  style: const TextStyle(fontWeight: FontWeight.w500)))
              .toList(),
        ),
      );
}

class _BikeProfileManager extends ConsumerStatefulWidget {
  const _BikeProfileManager({required this.bikes});
  final List<BikeProfile> bikes;

  @override
  ConsumerState<_BikeProfileManager> createState() =>
      _BikeProfileManagerState();
}

class _BikeProfileManagerState
    extends ConsumerState<_BikeProfileManager> {
  bool _showForm = false;
  BikeProfile? _editBike;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bike Profiles',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            TextButton.icon(
              onPressed: () => setState(() {
                _showForm = true;
                _editBike = null;
              }),
              icon: const Icon(Icons.add),
              label: const Text('New Profile'),
            ),
          ],
        ),
        ...widget.bikes.map((bike) => ListTile(
              title: Text(bike.name),
              subtitle: Text(bike.slug),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        setState(() {
                          _editBike = bike;
                          _showForm = true;
                        }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete bike?'),
                          content: Text('Delete "${bike.name}"?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) {
                        await ref
                            .read(bikesProvider.notifier)
                            .delete(bike.slug);
                      }
                    },
                  ),
                ],
              ),
            )),
        if (_showForm)
          _BikeForm(
            bike: _editBike,
            onSaved: (_) => setState(() => _showForm = false),
            onCancelled: () => setState(() => _showForm = false),
          ),
      ],
    );
  }
}

class _BikeForm extends ConsumerStatefulWidget {
  const _BikeForm({
    required this.bike,
    required this.onSaved,
    required this.onCancelled,
  });
  final BikeProfile? bike;
  final ValueChanged<BikeProfile> onSaved;
  final VoidCallback onCancelled;

  @override
  ConsumerState<_BikeForm> createState() => _BikeFormState();
}

class _BikeFormState extends ConsumerState<_BikeForm> {
  late final _nameCtrl =
      TextEditingController(text: widget.bike?.name ?? '');
  late final _slugCtrl =
      TextEditingController(text: widget.bike?.slug ?? '');

  // Numeric fields — initialised from the bike being edited, or T7 defaults.
  late final _wMaxFrontCtrl = _ctrl(widget.bike?.wMaxFrontMm ?? 210.0);
  late final _wMaxRearCtrl = _ctrl(widget.bike?.wMaxRearMm ?? 210.0);
  late final _forkAngleCtrl = _ctrl(widget.bike?.forkAngleDeg ?? 27.0);
  late final _cFrontCtrl = _ctrl(widget.bike?.cFront ?? 42.0);
  late final _v0FrontCtrl = _ctrl(widget.bike?.v0Front ?? 0.50);
  late final _cRearCtrl = _ctrl(widget.bike?.cRear ?? 18.5);
  late final _v0RearCtrl = _ctrl(widget.bike?.v0Rear ?? 0.40);
  late final _linkageACtrl = _ctrl(widget.bike?.linkageA ?? -0.015);
  late final _linkageBCtrl = _ctrl(widget.bike?.linkageB ?? 4.20);
  late final _linkageCCtrl = _ctrl(widget.bike?.linkageC ?? 0.0);
  late final _adcBitsCtrl = _ctrl(widget.bike?.adcBits ?? 12);
  late final _vRefCtrl = _ctrl(widget.bike?.vRef ?? 5.0);
  late final _fsHzCtrl = _ctrl(widget.bike?.fsHz ?? 250.0);
  late final _lpfDispCtrl = _ctrl(widget.bike?.lpfCutoffDispHz ?? 20.0);
  late final _lpfGyroCtrl = _ctrl(widget.bike?.lpfCutoffGyroHz ?? 10.0);
  late final _compAlphaCtrl = _ctrl(widget.bike?.complementaryAlpha ?? 0.98);
  late final _statSamplesCtrl = _ctrl(widget.bike?.stationarySamples ?? 250);
  late final _gyroSensCtrl = _ctrl(widget.bike?.gyroSensitivity ?? 16.4);
  late final _accelSensCtrl = _ctrl(widget.bike?.accelSensitivity ?? 2048.0);
  late final _lsThreshCtrl = _ctrl(widget.bike?.lsThresholdMmS ?? 150.0);

  TextEditingController _ctrl(num v) =>
      TextEditingController(text: v.toString());

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _slugCtrl,
      _wMaxFrontCtrl, _wMaxRearCtrl, _forkAngleCtrl,
      _cFrontCtrl, _v0FrontCtrl, _cRearCtrl, _v0RearCtrl,
      _linkageACtrl, _linkageBCtrl, _linkageCCtrl,
      _adcBitsCtrl, _vRefCtrl, _fsHzCtrl,
      _lpfDispCtrl, _lpfGyroCtrl, _compAlphaCtrl, _statSamplesCtrl,
      _gyroSensCtrl, _accelSensCtrl, _lsThreshCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final defaults = widget.bike ?? BikeProfile.t7;
    final profile = defaults.copyWith(
      name: _nameCtrl.text.trim(),
      slug: _slugCtrl.text.trim().toLowerCase().replaceAll(' ', '_'),
      wMaxFrontMm: double.tryParse(_wMaxFrontCtrl.text) ?? defaults.wMaxFrontMm,
      wMaxRearMm: double.tryParse(_wMaxRearCtrl.text) ?? defaults.wMaxRearMm,
      forkAngleDeg: double.tryParse(_forkAngleCtrl.text) ?? defaults.forkAngleDeg,
      cFront: double.tryParse(_cFrontCtrl.text) ?? defaults.cFront,
      v0Front: double.tryParse(_v0FrontCtrl.text) ?? defaults.v0Front,
      cRear: double.tryParse(_cRearCtrl.text) ?? defaults.cRear,
      v0Rear: double.tryParse(_v0RearCtrl.text) ?? defaults.v0Rear,
      linkageA: double.tryParse(_linkageACtrl.text) ?? defaults.linkageA,
      linkageB: double.tryParse(_linkageBCtrl.text) ?? defaults.linkageB,
      linkageC: double.tryParse(_linkageCCtrl.text) ?? defaults.linkageC,
      adcBits: int.tryParse(_adcBitsCtrl.text) ?? defaults.adcBits,
      vRef: double.tryParse(_vRefCtrl.text) ?? defaults.vRef,
      fsHz: double.tryParse(_fsHzCtrl.text) ?? defaults.fsHz,
      lpfCutoffDispHz: double.tryParse(_lpfDispCtrl.text) ?? defaults.lpfCutoffDispHz,
      lpfCutoffGyroHz: double.tryParse(_lpfGyroCtrl.text) ?? defaults.lpfCutoffGyroHz,
      complementaryAlpha: double.tryParse(_compAlphaCtrl.text) ?? defaults.complementaryAlpha,
      stationarySamples: int.tryParse(_statSamplesCtrl.text) ?? defaults.stationarySamples,
      gyroSensitivity: double.tryParse(_gyroSensCtrl.text) ?? defaults.gyroSensitivity,
      accelSensitivity: double.tryParse(_accelSensCtrl.text) ?? defaults.accelSensitivity,
      lsThresholdMmS: double.tryParse(_lsThreshCtrl.text) ?? defaults.lsThresholdMmS,
    );

    if (widget.bike != null) {
      await ref
          .read(bikesProvider.notifier)
          .updateBike(widget.bike!.slug, profile);
    } else {
      await ref.read(bikesProvider.notifier).create(profile);
    }
    widget.onSaved(profile);
  }

  Widget _numericField(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true, signed: true),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4, top: 4),
        child: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.grey)),
      );

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  widget.bike == null
                      ? 'New Bike Profile'
                      : 'Edit Bike Profile',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Identity
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _slugCtrl,
                decoration: const InputDecoration(
                    labelText: 'Slug (ID)',
                    border: OutlineInputBorder(),
                    isDense: true),
              ),
              const SizedBox(height: 4),

              // Travel limits & geometry
              _sectionLabel('Travel Limits & Geometry'),
              _numericField(_wMaxFrontCtrl, 'Max front travel (mm)'),
              _numericField(_wMaxRearCtrl, 'Max rear travel (mm)'),
              _numericField(_forkAngleCtrl, 'Fork angle (°)'),

              // Front calibration
              _sectionLabel('Front Calibration'),
              _numericField(_cFrontCtrl, 'C front (mm/V)'),
              _numericField(_v0FrontCtrl, 'V0 front (V)'),

              // Rear calibration
              _sectionLabel('Rear Calibration'),
              _numericField(_cRearCtrl, 'C rear (mm/V)'),
              _numericField(_v0RearCtrl, 'V0 rear (V)'),

              // Linkage polynomial
              _sectionLabel('Linkage Polynomial  W = A·s² + B·s + C'),
              _numericField(_linkageACtrl, 'Linkage A'),
              _numericField(_linkageBCtrl, 'Linkage B'),
              _numericField(_linkageCCtrl, 'Linkage C'),

              // ADC & acquisition
              _sectionLabel('ADC & Acquisition'),
              _numericField(_adcBitsCtrl, 'ADC bits'),
              _numericField(_vRefCtrl, 'V ref (V)'),
              _numericField(_fsHzCtrl, 'Sample rate (Hz)'),

              // Filters
              _sectionLabel('Signal Filters'),
              _numericField(_lpfDispCtrl, 'LPF disp cutoff (Hz)'),
              _numericField(_lpfGyroCtrl, 'LPF gyro cutoff (Hz)'),
              _numericField(_compAlphaCtrl, 'Complementary α'),
              _numericField(_statSamplesCtrl, 'Stationary samples'),

              // IMU sensitivity
              _sectionLabel('IMU Sensitivity'),
              _numericField(_gyroSensCtrl, 'Gyro sensitivity'),
              _numericField(_accelSensCtrl, 'Accel sensitivity'),

              // Advisor
              _sectionLabel('Advisor'),
              _numericField(_lsThreshCtrl, 'LS threshold (mm/s)'),

              const SizedBox(height: 8),
              Row(children: [
                ElevatedButton(
                    onPressed: _save, child: const Text('Save')),
                const SizedBox(width: 8),
                TextButton(
                    onPressed: widget.onCancelled,
                    child: const Text('Cancel')),
              ]),
            ],
          ),
        ),
      );
}

