import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Left-side navigation rail shell — wraps all top-level routes.
///
/// A custom scrollable sidebar is used instead of [NavigationRail] so that
/// the destination list can scroll on short screens (e.g., small phones in
/// landscape). The hamburger toggle at the top stays pinned and is never
/// clipped by the viewport.
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

  // ── Palette ────────────────────────────────────────────────────────────────
  static const _bgColor = Color(0xFF111827); // gray-900
  static const _activeColor = Color(0xFFF97316); // orange-500
  static const _inactiveColor = Color(0xFF9CA3AF); // gray-400
  static const _indicatorColor = Color(0x1FF97316); // orange-500 @ 12 %

  @override
  Widget build(BuildContext context) {
    final debugMode = ref.watch(debugModeProvider).valueOrNull ?? false;

    final entries = <({int branchIdx, IconData icon, IconData selectedIcon, String label})>[
      (branchIdx: 0, icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
      (branchIdx: 1, icon: Icons.upload_file_outlined, selectedIcon: Icons.upload_file, label: 'Import'),
      (branchIdx: 2, icon: Icons.tune_outlined, selectedIcon: Icons.tune, label: 'Calibrate'),
      (branchIdx: 3, icon: Icons.bar_chart_outlined, selectedIcon: Icons.bar_chart, label: 'Analyze'),
      (branchIdx: 4, icon: Icons.compare_arrows_outlined, selectedIcon: Icons.compare_arrows, label: 'Compare'),
      if (debugMode)
        (branchIdx: 5, icon: Icons.bug_report_outlined, selectedIcon: Icons.bug_report, label: 'Simulator'),
      (branchIdx: 6, icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
    ];

    final currentBranch = widget.navigationShell.currentIndex;
    final currentVisibleIdx =
        entries.indexWhere((e) => e.branchIdx == currentBranch);
    final selectedIdx = currentVisibleIdx >= 0 ? currentVisibleIdx : 0;

    final double railWidth = _extended ? 180.0 : 56.0;

    return Scaffold(
      body: Row(
        children: [
          // ── Scrollable sidebar ─────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: railWidth,
            color: _bgColor,
            child: SafeArea(
              child: Column(
                children: [
                  // Leading: pinned at top, never scrolls.
                  const SizedBox(height: 8),
                  _buildLeading(),
                  const SizedBox(height: 4),

                  // Destinations: scroll when the screen is too short.
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          for (int i = 0; i < entries.length; i++)
                            _buildDestination(
                              entry: entries[i],
                              isSelected: i == selectedIdx,
                              onTap: () {
                                widget.navigationShell.goBranch(
                                  entries[i].branchIdx,
                                  initialLocation: true,
                                );
                              },
                            ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ─────────────────────────────────────────────────────────
          const VerticalDivider(
              thickness: 1, width: 1, color: Color(0xFF1F2937)),

          // ── Screen content ───────────────────────────────────────────────────
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  Widget _buildLeading() {
    return Column(
      children: [
        SizedBox(
          height: 40,
          width: double.infinity,
          child: IconButton(
            icon: Icon(
              _extended ? Icons.menu_open : Icons.menu,
              color: Colors.white,
            ),
            tooltip: _extended ? 'Collapse menu' : 'Expand menu',
            onPressed: () => setState(() => _extended = !_extended),
          ),
        ),
        if (_extended) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.motorcycle, color: _activeColor, size: 18),
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
    );
  }

  Widget _buildDestination({
    required ({int branchIdx, IconData icon, IconData selectedIcon, String label}) entry,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? _activeColor : _inactiveColor;

    if (_extended) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? _indicatorColor : Colors.transparent,
                borderRadius: BorderRadius.circular(28),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    isSelected ? entry.selectedIcon : entry.icon,
                    color: color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      entry.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Collapsed: icon-only with centred indicator pill.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: entry.label,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected ? _indicatorColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Icon(
                  isSelected ? entry.selectedIcon : entry.icon,
                  color: color,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

