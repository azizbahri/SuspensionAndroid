import 'dart:io';
import 'dart:typed_data';

import '../../core/error/result.dart';
import '../../domain/entities/column_map.dart';
import '../hardware/daq_frame.dart';
import '../hardware/data_source.dart';

/// [DataSource] that reads a CSV file and produces [DaqFrame]s.
///
/// Column names are resolved via [ColumnMap]. Missing optional columns
/// (e.g., accel_y, accel_z) default to 0 counts.
class CsvDataSource extends DataSource {
  CsvDataSource({required this.csvPath, this.columnMap = const ColumnMap()});

  final String csvPath;
  final ColumnMap columnMap;

  @override
  String get name => 'CSV: ${csvPath.split('/').last}';

  @override
  Future<List<DaqFrame>> acquire() async {
    final file = File(csvPath);
    if (!file.existsSync()) {
      throw FileException('CSV file not found: $csvPath');
    }

    final lines = await file.readAsLines();
    if (lines.length < 2) {
      throw const ParseException('CSV file has no data rows');
    }

    final headers =
        lines.first.split(',').map((h) => h.trim()).toList();

    final timeCol = columnMap.timeCol;
    final timeIdx = timeCol != null ? headers.indexOf(timeCol) : -1;
    final frontIdx = headers.indexOf(columnMap.frontRawCol);
    final rearIdx = headers.indexOf(columnMap.rearRawCol);
    final gyroIdx = headers.indexOf(columnMap.gyroYCol);
    final axIdx = headers.indexOf(columnMap.accelXCol);
    final ayIdx = headers.indexOf(columnMap.accelYCol);
    final azIdx = headers.indexOf(columnMap.accelZCol);

    if (frontIdx < 0 || rearIdx < 0) {
      throw ParseException(
          'Required columns not found in CSV: '
          '${columnMap.frontRawCol}, ${columnMap.rearRawCol}');
    }

    final frames = <DaqFrame>[];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final parts = line.split(',');

      double? t;
      if (timeIdx >= 0 && timeIdx < parts.length) {
        t = double.tryParse(parts[timeIdx].trim());
      }

      int getInt(int idx) {
        if (idx < 0 || idx >= parts.length) return 0;
        return int.tryParse(parts[idx].trim()) ??
            double.tryParse(parts[idx].trim())?.round() ??
            0;
      }

      frames.add(DaqFrame(
        timeS: t,
        frontRaw: getInt(frontIdx),
        rearRaw: getInt(rearIdx),
        gyroYRaw: getInt(gyroIdx),
        accelXRaw: getInt(axIdx),
        accelYRaw: getInt(ayIdx),
        accelZRaw: getInt(azIdx),
      ));
    }

    return frames;
  }
}
