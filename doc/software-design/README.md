# Software Architecture — Suspension Study Android

> **Platform:** Android · **Language:** Dart · **Framework:** Flutter  
> No backend server. All signal processing runs on-device.

---

## System Context

```
┌─────────────────────────────────────────────────────────────────┐
│                     DataSource  (abstract)                       │
│                                                                  │
│  SimulatorSource ◄── SimulatorConfig (scenario, noise, seed)    │
│  CsvDataSource   ◄── file_picker → ColumnMap                    │
│  StubDaqSource   ◄── USB OTG placeholder (not yet implemented)  │
└──────────────────────────────┬──────────────────────────────────┘
                               │  List<DaqFrame>
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

---

## Layer Diagram

```
lib/
├── core/               Error types (Result<T>, AppException), math + format utils
├── data/
│   ├── processing/     Butterworth LPF, displacement, velocity, pitch, histograms, calibration
│   ├── advisor/        7-rule diagnostic advisor
│   ├── hardware/       DataSource interface + StubDaqSource (USB OTG placeholder) + CsvDataSource
│   ├── simulator/      PhysicsModel (6 scenarios), SensorModel, SimulatorSource
│   ├── local/          JSON file storage (bike profiles, sessions, results)
│   └── repositories/   Concrete repository implementations
├── domain/
│   ├── entities/       BikeProfile, Session, AnalysisResult + sub-models
│   ├── repositories/   Abstract interfaces
│   └── usecases/       Single-responsibility use cases
└── presentation/
    ├── providers/      Riverpod AsyncNotifier providers
    ├── widgets/        Reusable widgets (charts, diagnostic card, bike selector)
    └── screens/        Import, Calibrate, Analyze, Compare, Simulator, Settings
```

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| No backend server | All processing in Dart — offline-first, no network required |
| Abstract `DataSource` | Swappable between Simulator, CSV file, USB OTG, or BLE |
| `Result<T>` sealed class | Explicit error handling without exceptions crossing layer boundaries |
| `SimulatorSource` | Ported from Python `daq-simulate` — configurable from the app UI |
| JSON file storage | Simple, inspectable on-device storage |
| Riverpod `AsyncNotifier` | Structured async state with loading/error/data lifecycle |
| `minSdkVersion 31` | Android 12 — modern USB OTG APIs, BLE permissions, SAF file access |

---

## Hardware Abstraction Layer

`DataSource` is the only hardware contact point:

```dart
abstract class DataSource {
  String get name;
  bool get supportsStreaming => false;
  Future<List<DaqFrame>> acquire();
  Stream<DaqFrame> stream();
}
```

**To add USB OTG hardware:** implement `DataSource` in `data/hardware/usb_otg_source.dart`
and return it from `AnalysisRepositoryImpl._buildSource()`.

**To add BLE:** implement `DataSource` in `data/hardware/ble_source.dart` with
`supportsStreaming = true` and override `stream()`.

The current default is `SimulatorSource`. `StubDaqSource` is a non-functional placeholder
that will eventually be replaced with a real USB OTG or BLE implementation.

---

## Simulator

Six physically realistic scenarios are implemented in `PhysicsModel`:

| Scenario | Description |
|---|---|
| `staticSag` | Bike stationary at sag — baseline histogram |
| `braking` | Hard braking — front dive, rear unloading |
| `squareEdgeHit` | Single sharp-edged impact |
| `repeatedBumps` | Rhythmic compression — packing diagnostic |
| `jumpAndLanding` | Full travel compression on landing |
| `roughTerrain` | Band-limited Gaussian noise — typical trail riding |

`SensorModel` adds ADC quantisation and Gaussian noise (Box-Muller transform) on top of the physics output. The simulator is fully configurable from the **Simulator** screen in the app.

---

## Signal Processing

Ported 1:1 from the Python reference implementation (`backend/app/processing/`):

| Dart module | Equivalent Python source |
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

### Butterworth Filter

2nd-order Butterworth LPF via bilinear transform (prewarped). Zero-phase filtering via forward +
backward pass with odd-reflection padding. Matches `scipy.signal.butter(2, fc/(fs/2))` +
`scipy.signal.filtfilt()`.

### Velocity Sign Convention

Negative = compression, positive = rebound. The wheel travel `W` increases as the
suspension compresses (sensor extends). The time derivative is negated so compression events
appear as negative velocity in the histogram.

### Complementary Filter (pitch)

```
ϕ_acc[n] = atan2(−ax_g[n], √(ay_g²[n] + az_g²[n]))   [deg]
ϕ[n]     = α × (ϕ[n-1] + 0.5 × (ω_f[n] + ω_f[n-1]) × dt)
           + (1 − α) × ϕ_acc[n]
α = 0.98
```

Gyro-only integration is never used. The accelerometer continuously corrects drift.

---

## Diagnostic Advisor

Seven rules run on every `AnalysisResult`:

| Rule ID | Trigger |
|---|---|
| `deep_travel_tail` | `pct_above_80 > 10 %` |
| `travel_center_shifted_right` | `peak_center > 50 %` |
| `travel_center_shifted_left` | `peak_center < 20 %` |
| `harsh_hs_compression` | `hs_compression_pct > 20 %` |
| `brake_dive` | `pitch < −15°` with LS compression dominant |
| `compression_asymmetry` | `comp > reb × 1.5` |
| `rebound_kickback` | `reb > comp × 1.5` |

Each rule is a pure function. Exceptions inside rules are swallowed so one misbehaving rule
cannot abort the pipeline.

---

## Android Configuration

| Setting | Value |
|---|---|
| `minSdkVersion` | 31 (Android 12) |
| `targetSdkVersion` | 35 |
| USB host feature | declared in `AndroidManifest.xml` |
| BLE permissions | `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (pre-declared for future BLE source) |

The USB device filter (`android/app/src/main/res/xml/device_filter.xml`) is a placeholder.
Update it with the DAQ VID/PID once the hardware is known:

```xml
<usb-device vendor-id="1027" product-id="24577" />
```

---

## Testing

```bash
cd frontend_flutter

# Dart analysis (static type checking + lints)
flutter analyze

# Unit tests (no device required)
flutter test test/unit/

# All tests
flutter test
```

Test coverage includes:

- `SignalFilter` — Butterworth coefficients vs scipy reference, filtfilt DC/LP/HP gain, zero-phase
- `DisplacementProcessor`, `VelocityProcessor`, `PitchProcessor`
- `MathUtils` — polyfit1, polyfit2, std dev, histogram, RMSE
- `CalibrationFitter` — exact coefficient recovery (front linear, rear quadratic)
- `PhysicsModel` — all 6 scenarios
- `SimulatorSource` — end-to-end round-trip (histogram sums, pitch trace length, LS/HS breakdown)
- Use case validation — `CompareSessions`, `CalibrateFront`, `CalibrateRear`, `CreateBike`
- Widget tests — `DiagnosticCard`, `TravelHistogramChart`, `BikeSelector`
