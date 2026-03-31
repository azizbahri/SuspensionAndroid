import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/entities/bike_profile.dart';
import '../../../lib/presentation/widgets/bike_selector.dart';

void main() {
  final bikes = const [
    BikeProfile(name: 'Yamaha Ténéré 700', slug: 't7'),
    BikeProfile(name: 'KTM 890 Adventure', slug: 'ktm890'),
  ];

  testWidgets('shows placeholder when no slug selected', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BikeSelector(
          bikes: bikes,
          selectedSlug: null,
          onChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('Select bike…'), findsOneWidget);
  });

  testWidgets('shows all bike names as options', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BikeSelector(
          bikes: bikes,
          selectedSlug: null,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Yamaha Ténéré 700'), findsWidgets);
    expect(find.text('KTM 890 Adventure'), findsOneWidget);
  });

  testWidgets('calls onChanged with correct slug when selected', (tester) async {
    String? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BikeSelector(
          bikes: bikes,
          selectedSlug: null,
          onChanged: (slug) => selected = slug,
        ),
      ),
    ));
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('KTM 890 Adventure').last);
    await tester.pumpAndSettle();
    expect(selected, 'ktm890');
  });

  testWidgets('shows controlled value', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BikeSelector(
          bikes: bikes,
          selectedSlug: 't7',
          onChanged: (_) {},
        ),
      ),
    ));
    expect(find.text('Yamaha Ténéré 700'), findsOneWidget);
  });
}
