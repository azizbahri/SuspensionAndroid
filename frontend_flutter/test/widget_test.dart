// Smoke test: verify that the app root widget can be pumped without crashing.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:suspension_android/app/app.dart';

void main() {
  testWidgets('App smoke test — renders without throwing', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SuspensionApp()),
    );
    // Just verify the app inflates without exceptions.
    expect(tester.takeException(), isNull);
  });
}
