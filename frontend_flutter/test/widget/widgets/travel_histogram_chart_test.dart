import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/entities/analysis_result.dart';
import '../../../lib/presentation/widgets/travel_histogram_chart.dart';

void main() {
  TravelHistogram makeHistogram({bool allZero = false}) => TravelHistogram(
        centersPct: List.generate(10, (i) => i * 10.0 + 5.0),
        timePct: allZero
            ? List.filled(10, 0.0)
            : List.generate(10, (i) => i == 3 ? 40.0 : 5.0),
        peakCenterPct: allZero ? 5.0 : 35.0,
        pctAbove80: allZero ? 0.0 : 5.0,
      );

  Widget buildChart({bool allZero = false}) => MaterialApp(
        home: Scaffold(
          body: TravelHistogramChart(
            data: makeHistogram(allZero: allZero),
            title: 'Travel Distribution',
          ),
        ),
      );

  testWidgets('renders title', (tester) async {
    await tester.pumpWidget(buildChart());
    expect(find.text('Travel Distribution'), findsOneWidget);
  });

  testWidgets('shows peak statistic', (tester) async {
    await tester.pumpWidget(buildChart());
    expect(find.textContaining('35.0%'), findsWidgets);
  });

  testWidgets('shows above-80% statistic', (tester) async {
    await tester.pumpWidget(buildChart());
    expect(find.textContaining('5.0%'), findsWidgets);
  });

  testWidgets('does not crash with all-zero data', (tester) async {
    await tester.pumpWidget(buildChart(allZero: true));
    expect(tester.takeException(), isNull);
  });
}
