import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell — wraps all top-level routes.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Import'),
    BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Calibrate'),
    BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analyze'),
    BottomNavigationBarItem(
        icon: Icon(Icons.compare_arrows), label: 'Compare'),
    BottomNavigationBarItem(icon: Icon(Icons.bug_report), label: 'Simulator'),
    BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: navigationShell.currentIndex,
        selectedItemColor: const Color(0xFFF97316), // orange-500
        unselectedItemColor: Colors.grey,
        onTap: (index) =>
            navigationShell.goBranch(index, initialLocation: true),
        items: _items,
      ),
    );
  }
}
