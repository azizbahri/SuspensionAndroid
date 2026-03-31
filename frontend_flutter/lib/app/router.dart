import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/local/bike_storage.dart';
import '../presentation/providers/providers.dart';
import '../presentation/screens/import_session/import_screen.dart';
import '../presentation/screens/calibrate/calibrate_screen.dart';
import '../presentation/screens/analyze/analyze_screen.dart';
import '../presentation/screens/compare/compare_screen.dart';
import '../presentation/screens/simulator/simulator_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/widgets/app_shell.dart';

/// GoRouter configuration.
///
/// Routes use a StatefulShellRoute so each tab retains its navigation stack.
/// The Simulator branch is always included in the route tree but only shown
/// in the [AppShell] bottom nav when debug mode is enabled.
final GoRouter appRouter = GoRouter(
  initialLocation: '/import',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/import',
            builder: (_, __) => const ImportScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/calibrate',
            builder: (_, __) => const CalibrateScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/analyze',
            builder: (_, state) => AnalyzeScreen(
              preselectedSessionId:
                  state.uri.queryParameters['session'],
            ),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/compare',
            builder: (_, __) => const CompareScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/simulator',
            builder: (_, __) => const SimulatorScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ]),
      ],
    ),
  ],
);
