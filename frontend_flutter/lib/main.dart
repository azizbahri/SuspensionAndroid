import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/local/bike_storage.dart';

/// Entry point.
///
/// Seeds the default T7 bike profile on first launch so the app is
/// immediately usable without manual setup.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Seed default bike profile if storage is empty
  await BikeStorage().seedDefaults();

  runApp(
    const ProviderScope(
      child: SuspensionApp(),
    ),
  );
}
