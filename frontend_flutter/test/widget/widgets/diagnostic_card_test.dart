import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/domain/entities/analysis_result.dart';
import '../../../lib/presentation/widgets/diagnostic_card.dart';

void main() {
  Widget buildCard(DiagnosticNote note) => MaterialApp(
        home: Scaffold(body: DiagnosticCard(note: note)),
      );

  final infoNote = const DiagnosticNote(
    ruleId: 'test_info',
    severity: DiagnosticSeverity.info,
    title: 'Info Title',
    message: 'Info message body',
    action: 'Do nothing',
  );

  final warningNote = const DiagnosticNote(
    ruleId: 'test_warn',
    severity: DiagnosticSeverity.warning,
    title: 'Warning Title',
    message: 'Warning message',
    action: 'Check suspension',
  );

  final criticalNote = const DiagnosticNote(
    ruleId: 'test_crit',
    severity: DiagnosticSeverity.critical,
    title: 'Critical Title',
    message: 'Critical message',
    action: 'Act immediately',
  );

  testWidgets('renders title and message for info severity', (tester) async {
    await tester.pumpWidget(buildCard(infoNote));
    expect(find.text('Info Title'), findsOneWidget);
    expect(find.text('Info message body'), findsOneWidget);
    expect(find.text('info'), findsOneWidget);
  });

  testWidgets('renders warning badge', (tester) async {
    await tester.pumpWidget(buildCard(warningNote));
    expect(find.text('warning'), findsOneWidget);
    expect(find.text('Warning Title'), findsOneWidget);
  });

  testWidgets('renders critical badge', (tester) async {
    await tester.pumpWidget(buildCard(criticalNote));
    expect(find.text('critical'), findsOneWidget);
    expect(find.text('Critical Title'), findsOneWidget);
  });

  testWidgets('renders action text with arrow prefix', (tester) async {
    await tester.pumpWidget(buildCard(warningNote));
    expect(find.textContaining('Check suspension'), findsOneWidget);
  });

  testWidgets('all severity levels render without crash', (tester) async {
    for (final severity in DiagnosticSeverity.values) {
      await tester.pumpWidget(buildCard(DiagnosticNote(
        ruleId: 'test',
        severity: severity,
        title: 'Title',
        message: 'Message',
        action: 'Action',
      )));
      expect(tester.takeException(), isNull);
    }
  });
}
