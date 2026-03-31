import 'package:flutter/material.dart';

import '../../domain/entities/analysis_result.dart';

/// Severity-styled card for a single [DiagnosticNote].
///
/// Mirrors the React DiagnosticCard component:
///   info     → grey border / badge
///   warning  → yellow border / badge
///   critical → red border / badge
class DiagnosticCard extends StatelessWidget {
  const DiagnosticCard({super.key, required this.note});

  final DiagnosticNote note;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(note.severity);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: style.borderColor, width: 4)),
        color: style.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: style.badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  note.severity.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: style.badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ]),
            const SizedBox(height: 6),
            Text(note.message, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              '→ ${note.action}',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static _DiagnosticStyle _styleFor(DiagnosticSeverity severity) {
    return switch (severity) {
      DiagnosticSeverity.critical => _DiagnosticStyle(
          borderColor: Colors.red.shade600,
          backgroundColor: Colors.red.shade50,
          badgeColor: Colors.red.shade200,
          badgeTextColor: Colors.red.shade900,
        ),
      DiagnosticSeverity.warning => _DiagnosticStyle(
          borderColor: Colors.orange.shade500,
          backgroundColor: Colors.orange.shade50,
          badgeColor: Colors.orange.shade200,
          badgeTextColor: Colors.orange.shade900,
        ),
      DiagnosticSeverity.info => _DiagnosticStyle(
          borderColor: Colors.grey.shade400,
          backgroundColor: Colors.grey.shade50,
          badgeColor: Colors.grey.shade200,
          badgeTextColor: Colors.grey.shade800,
        ),
    };
  }
}

class _DiagnosticStyle {
  const _DiagnosticStyle({
    required this.borderColor,
    required this.backgroundColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });
  final Color borderColor;
  final Color backgroundColor;
  final Color badgeColor;
  final Color badgeTextColor;
}
