import 'daq_frame.dart';

/// Abstract interface for any data source that produces [DaqFrame] sequences.
///
/// Current implementations:
///   [SimulatorSource] — generates physically realistic data from the built-in
///     physics model (debug / development mode).
///   [StubDaqSource] — placeholder for future USB OTG hardware integration.
///   [CsvDataSource] — reads a CSV file chosen via file_picker (offline analysis).
///
/// Future implementations:
///   BleDataSource — streams live frames from a BLE DAQ logger.
///   UsbOtgDataSource — reads live frames over USB host connection.
///
/// Concrete implementations live in data/hardware/ or data/simulator/.
abstract class DataSource {
  /// Human-readable name for display in the UI.
  String get name;

  /// True if this source supports live streaming (i.e., produces frames
  /// continuously rather than returning a fixed-length batch).
  bool get supportsStreaming => false;

  /// Acquire a complete batch of [DaqFrame]s.
  ///
  /// For offline sources (CSV, simulator) this returns all frames at once.
  /// For live sources this may block until acquisition is complete.
  Future<List<DaqFrame>> acquire();

  /// Stream of frames for live sources.
  ///
  /// Default implementation wraps [acquire()] for batch sources.
  /// Override in live-hardware implementations.
  Stream<DaqFrame> stream() =>
      Stream.fromFuture(acquire()).expand((frames) => frames);
}

/// Identifies the runtime type of a [DataSource] for persistence.
enum DataSourceType {
  simulator,
  csvFile,
  usbOtg,
  ble,
}
