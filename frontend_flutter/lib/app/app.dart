import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

/// Root application widget.
///
/// Wrapped in [ProviderScope] in [main.dart] to inject the Riverpod dependency
/// graph. [MaterialApp.router] is used with [appRouter] for declarative routing.
class SuspensionApp extends StatelessWidget {
  const SuspensionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Suspension Study',
      theme: appTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
