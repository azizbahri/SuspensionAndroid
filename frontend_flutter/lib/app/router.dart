import 'package:go_router/go_router.dart';

import '../presentation/screens/dashboard/dashboard_screen.dart';
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
/// Branch indices (fixed):
///   0 = /dashboard, 1 = /import, 2 = /calibrate, 3 = /analyze,
///   4 = /compare,   5 = /simulator,  6 = /settings
///
/// The Simulator branch is always in the route tree but only shown in the
/// [AppShell] bottom nav when debug mode is enabled.
final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, shell) => AppShell(navigationShell: shell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
        ]),
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
