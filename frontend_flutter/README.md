# Suspension Study — Flutter App

Pure Flutter/Dart mobile application for motorcycle suspension DAQ analysis.  
No backend server. All signal processing runs on-device in Dart.

## Architecture

```
lib/
├── core/           # Error types (Result<T>, AppException), math + format utils
├── data/
│   ├── processing/ # Butterworth LPF, displacement, velocity, pitch, histograms, calibration
│   ├── advisor/    # 7-rule diagnostic advisor
│   ├── hardware/   # DataSource interface + StubDaqSource (USB OTG placeholder) + CsvDataSource
│   ├── simulator/  # PhysicsModel (6 scenarios), SensorModel, SimulatorSource
│   ├── local/      # JSON file storage (bike profiles, sessions, results)
│   └── repositories/ # Concrete repository implementations
├── domain/
│   ├── entities/   # BikeProfile, Session, AnalysisResult + sub-models
│   ├── repositories/ # Abstract interfaces
│   └── usecases/   # Single-responsibility use cases
└── presentation/
    ├── providers/  # Riverpod AsyncNotifier providers
    ├── widgets/    # Reusable widgets (charts, diagnostic card, bike selector)
    └── screens/    # Import, Calibrate, Analyze, Compare, Simulator, Settings
```

### Key Design Decisions

| Decision | Rationale |
|---|---|
| No backend server | All processing in Dart — no network required, offline-first |
| Abstract `DataSource` | Swappable between Simulator, CSV file, USB OTG, BLE |
| `Result<T>` sealed class | Explicit error handling without exceptions crossing layer boundaries |
| `SimulatorSource` | Ported from Python `daq-simulate` — configurable from the app UI |
| JSON file storage | Simple, inspectable, matches Python backend layout |
| Riverpod `AsyncNotifier` | Structured async state with loading/error/data lifecycle |
| minSdkVersion 31 | Android 12 — modern USB OTG APIs, SAF file access |

## Setup

### Prerequisites

- Flutter SDK ≥ 3.22.0
- Dart SDK ≥ 3.4.0
- Android SDK with API 31+
- An Android device or emulator (API 31+)

### 1. Scaffold the Flutter project

This repository contains only the `lib/`, `test/`, `android/`, and `pubspec.yaml` files.
Use `flutter create` to generate the remaining boilerplate (gradle wrappers, platform channels, etc.):

```bash
cd frontend_flutter

# Create a temporary project to get the boilerplate
flutter create --project-name suspension_android \
               --org com.suspensionstudy \
               --platforms android \
               .
```

This will fill in:
- `android/` gradle wrapper, settings.gradle, etc.
- `lib/main.dart` (overwrite with the one in this repo)
- Test runner configuration

> **Note:** If `flutter create` would overwrite files, use `--overwrite` or merge manually.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Run on device

```bash
flutter run
```

### 4. Run tests

```bash
# Unit tests only (no device required)
flutter test test/unit/

# All tests (requires device/emulator for widget tests)
flutter test
```

## Data Flow

```
 ┌─────────────────────────────────────────────────────────────┐
 │                       DataSource (abstract)                  │
 │                                                              │
 │   SimulatorSource ◄── SimulatorConfig (scenario, noise)     │
 │   CsvDataSource   ◄── file_picker → ColumnMap               │
 │   StubDaqSource   ◄── (USB OTG — not yet implemented)       │
 └──────────────────────────────┬──────────────────────────────┘
                                │ List<DaqFrame>
                                ▼
                      SessionPipeline.process()
                                │
              ┌─────────────────┼─────────────────┐
              ▼                 ▼                 ▼
   DisplacementProcessor  VelocityProcessor  PitchProcessor
              │                 │                 │
              ▼                 ▼                 ▼
       HistogramBuilder   HistogramBuilder  DiagnosticAdvisor
              │                 │                 │
              └─────────────────┼─────────────────┘
                                ▼
                          AnalysisResult
                                │
                         SessionStorage
                         (JSON to disk)
```

## Signal Processing

Ported 1:1 from the Python backend (`backend/app/processing/`):

| Module | Source |
|---|---|
| `SignalFilter` | `displacement.py`, `velocity.py`, `pitch.py` |
| `DisplacementProcessor` | `displacement.py` |
| `VelocityProcessor` | `velocity.py` |
| `PitchProcessor` | `pitch.py` |
| `HistogramBuilder` | `histograms.py` |
| `CalibrationFitter` | `calibration.py` |
| `DiagnosticAdvisor` | `advisor/rules.py` |
| `PhysicsModel` | `simulator/physics.py` |
| `SensorModel` | `simulator/sensors.py` |

### Butterworth Filter Notes

2nd-order Butterworth LPF implemented via bilinear transform (prewarped).
Zero-phase filtering via forward + backward pass with odd-reflection padding.
Matches `scipy.signal.butter(2, fc/(fs/2)) + scipy.signal.filtfilt()`.

## Hardware Abstraction Layer

The `DataSource` interface is the only hardware contact point:

```dart
abstract class DataSource {
  String get name;
  bool get supportsStreaming => false;
  Future<List<DaqFrame>> acquire();
  Stream<DaqFrame> stream();
}
```

To add USB OTG hardware: implement `DataSource` in `data/hardware/usb_otg_source.dart`
and return it from `AnalysisRepositoryImpl._buildSource()`.

To add BLE: implement `DataSource` in `data/hardware/ble_source.dart` with
`supportsStreaming = true` and override `stream()`.

## Android USB OTG Configuration

See `android/app/src/main/AndroidManifest.xml` and
`android/app/src/main/res/xml/device_filter.xml`.

The device filter currently accepts any USB device (placeholder). Once the DAQ
hardware VID/PID are known, update `device_filter.xml`:

```xml
<usb-device vendor-id="1027" product-id="24577" />
```

## Minimum SDK

`minSdkVersion = 31` (Android 12). Set in `android/app/build.gradle`.

Rationale:
- Modern `UsbManager` APIs stable
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` without legacy `BLUETOOTH` permissions
- Storage Access Framework for file_picker without `READ_EXTERNAL_STORAGE`
