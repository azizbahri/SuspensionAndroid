/// A single frame of DAQ sensor data — the atomic unit produced by any [DataSource].
///
/// Field names mirror the Python backend CSV columns:
///   time_s, front_raw, rear_raw, gyro_y_raw, accel_x_raw, accel_y_raw, accel_z_raw
///
/// For USB OTG or BLE hardware that streams at a fixed rate, [timeS] may be
/// null and is reconstructed from the sample index × dt in the pipeline.
class DaqFrame {
  const DaqFrame({
    this.timeS,
    required this.frontRaw,
    required this.rearRaw,
    required this.gyroYRaw,
    required this.accelXRaw,
    required this.accelYRaw,
    required this.accelZRaw,
  });

  /// Elapsed time in seconds (nullable — generated from fs if absent).
  final double? timeS;

  /// Front potentiometer ADC count (12-bit integer, 0–4095).
  final int frontRaw;

  /// Rear shock potentiometer ADC count (12-bit integer, 0–4095).
  final int rearRaw;

  /// IMU Y-axis gyroscope (signed int16, pitch rate).
  final int gyroYRaw;

  /// IMU X-axis accelerometer (signed int16, longitudinal).
  final int accelXRaw;

  /// IMU Y-axis accelerometer (signed int16, lateral).
  final int accelYRaw;

  /// IMU Z-axis accelerometer (signed int16, vertical).
  final int accelZRaw;

  @override
  String toString() =>
      'DaqFrame(t=${timeS?.toStringAsFixed(4)}, '
      'f=$frontRaw, r=$rearRaw, gy=$gyroYRaw)';
}
