import 'package:flutter/material.dart';

import '../../domain/entities/bike_profile.dart';

/// Controlled dropdown for selecting a [BikeProfile].
///
/// Mirrors the React BikeSelector component.
class BikeSelector extends StatelessWidget {
  const BikeSelector({
    super.key,
    required this.bikes,
    required this.selectedSlug,
    required this.onChanged,
    this.hint = 'Select bike…',
  });

  final List<BikeProfile> bikes;
  final String? selectedSlug;
  final ValueChanged<String?> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedSlug,
      hint: Text(hint),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
      ),
      items: bikes
          .map((b) => DropdownMenuItem(value: b.slug, child: Text(b.name)))
          .toList(),
      onChanged: onChanged,
    );
  }
}
