import 'package:flutter/material.dart';

/// Material 3 theme for Suspension Study.
///
/// Primary brand colour: Orange 500 (#F97316).
/// Uses Material 3 with a dark-capable color scheme.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorSchemeSeed: const Color(0xFFF97316),
  brightness: Brightness.light,
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
  ),
  cardTheme: CardTheme(
    elevation: 1,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
    isDense: true,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFF97316),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
  ),
);
