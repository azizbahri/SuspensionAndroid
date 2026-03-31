import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Left-side navigation rail shell — wraps all top-level routes.
///
/// A [NavigationRail] is displayed on the left. Tapping the leading menu
/// icon toggles between icon-only (collapsed) and icons+labels (extended).
///
/// Branch indices in the route tree (fixed):
///   0=Dashboard, 1=Import, 2=Calibrate, 3=Analyze,
///   4=Compare,   5=Simulator,  6=Settings
///
/// The Simulator destination (branch 5) is only shown when debug mode is ON.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _extended = false;

  @override
  Widget build(BuildContext context) {
    final debugMode =
        ref.watch(debugModeProvider).valueOrNull ?? false;

    // Build the list of (branchIndex, destination) pairs that are visible.
    final entries = <({int branchIdx, NavigationRailDestination dest})>[
      (
        branchIdx: 0,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: Text('Home'),
        ),
      ),
      (
        branchIdx: 1,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.upload_file_outlined),
          selectedIcon: Icon(Icons.upload_file),
          label: Text('Import'),
        ),
      ),
      (
        branchIdx: 2,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: Text('Calibrate'),
        ),
      ),
      (
        branchIdx: 3,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Analyze'),
        ),
      ),
      (
        branchIdx: 4,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.compare_arrows_outlined),
          selectedIcon: Icon(Icons.compare_arrows),
          label: Text('Compare'),
        ),
      ),
      if (debugMode)
        (
          branchIdx: 5,
          dest: const NavigationRailDestination(
            icon: Icon(Icons.bug_report_outlined),
            selectedIcon: Icon(Icons.bug_report),
            label: Text('Simulator'),
          ),
        ),
      (
        branchIdx: 6,
        dest: const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ),
    ];

    // Map current branch → visible rail index (default 0 if branch is hidden).
    final currentBranch = widget.navigationShell.currentIndex;
    final visibleIdx =
        entries.indexWhere((e) => e.branchIdx == currentBranch);
    final currentRailIdx = visibleIdx >= 0 ? visibleIdx : 0;

    return Scaffold(
      body: Row(
        children: [
          // ── Navigation Rail ──────────────────────────────────────────────
          NavigationRail(
            extended: _extended,
            minWidth: 56,
            minExtendedWidth: 180,
            backgroundColor: const Color(0xFF111827), // gray-900
            selectedIconTheme:
                const IconThemeData(color: Color(0xFFF97316)), // orange-500
            unselectedIconTheme:
                const IconThemeData(color: Color(0xFF9CA3AF)), // gray-400
            selectedLabelTextStyle: const TextStyle(
                color: Color(0xFFF97316), fontWeight: FontWeight.w600),
            unselectedLabelTextStyle:
                const TextStyle(color: Color(0xFF9CA3AF)),
            indicatorColor:
                const Color(0xFFF97316).withOpacity(0.12), // subtle orange pill
            leading: Column(
              children: [
                const SizedBox(height: 8),
                IconButton(
                  icon: Icon(
                    _extended ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  tooltip:
                      _extended ? 'Collapse menu' : 'Expand menu',
                  onPressed: () =>
                      setState(() => _extended = !_extended),
                ),
                if (_extended) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.motorcycle,
                          color: Color(0xFFF97316), size: 18),
                      SizedBox(width: 6),
                      Text(
                        'Suspension',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ] else
                  const SizedBox(height: 8),
              ],
            ),
            destinations: entries.map((e) => e.dest).toList(),
            selectedIndex: currentRailIdx,
            onDestinationSelected: (idx) {
              widget.navigationShell.goBranch(
                entries[idx].branchIdx,
                initialLocation: true,
              );
            },
          ),

          // ── Divider ──────────────────────────────────────────────────────
          const VerticalDivider(
              thickness: 1, width: 1, color: Color(0xFF1F2937)),

          // ── Screen content ───────────────────────────────────────────────
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}

