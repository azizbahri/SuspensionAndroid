import '../../core/error/result.dart';
import 'daq_frame.dart';
import 'data_source.dart';

/// Placeholder [DataSource] for future USB OTG hardware integration.
///
/// Declares the USB host intent to the rest of the system but throws
/// [HardwareException] on any data acquisition attempt until the hardware
/// driver is implemented.
///
/// Replace this class body with a real USB serial / custom protocol driver
/// once the DAQ hardware and its communication protocol are known.
class StubDaqSource extends DataSource {
  const StubDaqSource();

  @override
  String get name => 'USB OTG DAQ (not connected)';

  @override
  bool get supportsStreaming => true; // will support streaming when implemented

  @override
  Future<List<DaqFrame>> acquire() async {
    throw const HardwareException(
      'USB OTG hardware driver is not yet implemented. '
      'Use the Simulator source for development and testing.',
    );
  }

  @override
  Stream<DaqFrame> stream() =>
      Stream.error(const HardwareException(
        'USB OTG streaming is not yet implemented.',
      ));
}
