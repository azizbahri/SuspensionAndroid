import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/providers.dart';

/// Bottom navigation shell — wraps all top-level routes.
///
/// Branch indices in the route tree (fixed):
///   0=Dashboard, 1=Import, 2=Calibrate, 3=Analyze,
///   4=Compare,   5=Simulator,  6=Settings
///
/// The Simulator tab (branch 5) is only shown when debug mode is ON.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugMode = ref.watch(debugModeProvider).valueOrNull ?? false;

    // Build the list of (branchIndex, navItem) pairs that are visible.
    final entries = <({int branchIdx, BottomNavigationBarItem item})>[
      (
        branchIdx: 0,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Home'),
      ),
      (
        branchIdx: 1,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.upload_file), label: 'Import'),
      ),
      (
        branchIdx: 2,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.tune), label: 'Calibrate'),
      ),
      (
        branchIdx: 3,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), label: 'Analyze'),
      ),
      (
        branchIdx: 4,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows), label: 'Compare'),
      ),
      if (debugMode)
        (
          branchIdx: 5,
          item: const BottomNavigationBarItem(
              icon: Icon(Icons.bug_report), label: 'Simulator'),
        ),
      (
        branchIdx: 6,
        item: const BottomNavigationBarItem(
            icon: Icon(Icons.settings), label: 'Settings'),
      ),
    ];

    // Map current branch index → visible tab index.
    final currentBranch = navigationShell.currentIndex;
    final visibleIdx = entries.indexWhere((e) => e.branchIdx == currentBranch);
    // If current branch is hidden (e.g. simulator tab hidden), default to 0.
    final currentTabIdx = visibleIdx >= 0 ? visibleIdx : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentTabIdx,
        selectedItemColor: const Color(0xFFF97316), // orange-500
        unselectedItemColor: Colors.grey,
        onTap: (idx) {
          final branchIdx = entries[idx].branchIdx;
          navigationShell.goBranch(branchIdx, initialLocation: true);
        },
        items: entries.map((e) => e.item).toList(),
      ),
    );
  }
}
