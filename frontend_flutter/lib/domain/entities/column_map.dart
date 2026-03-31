import 'dart:convert';

/// Maps CSV column names to DAQ signal channels and declares polarity inversions.
///
/// Mirrors the Python ColumnMap Pydantic model.
/// When data comes from the [SimulatorSource] the column names are irrelevant
/// (DaqFrame already has typed fields). The inversion flags still apply.
class ColumnMap {
  const ColumnMap({
    this.timeCol = 'time_s',
    this.frontRawCol = 'front_raw',
    this.rearRawCol = 'rear_raw',
    this.gyroYCol = 'gyro_y_raw',
    this.accelXCol = 'accel_x_raw',
    this.accelYCol = 'accel_y_raw',
    this.accelZCol = 'accel_z_raw',
    this.invertFront = false,
    this.invertRear = false,
  });

  final String? timeCol;
  final String frontRawCol;
  final String rearRawCol;
  final String gyroYCol;
  final String accelXCol;
  final String accelYCol;
  final String accelZCol;
  final bool invertFront;
  final bool invertRear;

  ColumnMap copyWith({
    String? timeCol,
    String? frontRawCol,
    String? rearRawCol,
    String? gyroYCol,
    String? accelXCol,
    String? accelYCol,
    String? accelZCol,
    bool? invertFront,
    bool? invertRear,
  }) =>
      ColumnMap(
        timeCol: timeCol ?? this.timeCol,
        frontRawCol: frontRawCol ?? this.frontRawCol,
        rearRawCol: rearRawCol ?? this.rearRawCol,
        gyroYCol: gyroYCol ?? this.gyroYCol,
        accelXCol: accelXCol ?? this.accelXCol,
        accelYCol: accelYCol ?? this.accelYCol,
        accelZCol: accelZCol ?? this.accelZCol,
        invertFront: invertFront ?? this.invertFront,
        invertRear: invertRear ?? this.invertRear,
      );

  Map<String, dynamic> toJson() => {
        'time_col': timeCol,
        'front_raw_col': frontRawCol,
        'rear_raw_col': rearRawCol,
        'gyro_y_col': gyroYCol,
        'accel_x_col': accelXCol,
        'accel_y_col': accelYCol,
        'accel_z_col': accelZCol,
        'invert_front': invertFront,
        'invert_rear': invertRear,
      };

  factory ColumnMap.fromJson(Map<String, dynamic> json) => ColumnMap(
        timeCol: json['time_col'] as String?,
        frontRawCol: json['front_raw_col'] as String? ?? 'front_raw',
        rearRawCol: json['rear_raw_col'] as String? ?? 'rear_raw',
        gyroYCol: json['gyro_y_col'] as String? ?? 'gyro_y_raw',
        accelXCol: json['accel_x_col'] as String? ?? 'accel_x_raw',
        accelYCol: json['accel_y_col'] as String? ?? 'accel_y_raw',
        accelZCol: json['accel_z_col'] as String? ?? 'accel_z_raw',
        invertFront: json['invert_front'] as bool? ?? false,
        invertRear: json['invert_rear'] as bool? ?? false,
      );

  String toJsonString() => jsonEncode(toJson());
  factory ColumnMap.fromJsonString(String s) =>
      ColumnMap.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
