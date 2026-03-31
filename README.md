# Suspension Study — Android

A native Android application for motorcycle suspension DAQ analysis, built in Flutter/Dart.
All signal processing runs **on-device** — no backend server, no network required.

Primary target: **Yamaha Ténéré 700** (T7), with T7 linkage constants pre-populated.
Other bikes can be added through the Calibrate screen.

---

## Quick Start

### Prerequisites

- Flutter SDK ≥ 3.22.0
- Android SDK with API 31+ (Android 12)
- An Android device or emulator (API 31+)

### 1. Scaffold the Flutter project

The repository ships `lib/`, `test/`, `android/`, and `pubspec.yaml`.
Run `flutter create` once to generate the remaining Gradle boilerplate:

```bash
cd frontend_flutter
flutter create --project-name suspension_android \
               --org com.suspensionstudy \
               --platforms android \
               .
```

> Use `--overwrite` if prompted, or manually merge generated files with the ones already present.

### 2. Install dependencies

```bash
cd frontend_flutter
flutter pub get
```

### 3. Run on device

```bash
cd frontend_flutter
flutter run
```

### 4. Run tests

```bash
cd frontend_flutter

# Unit tests only (no device required)
flutter test test/unit/

# All tests
flutter test
```

---

## Documentation

Theoretical framework: [doc/foundation/overview.md](doc/foundation/overview.md)  
Documentation index: [doc/README.md](doc/README.md)  
App architecture: [doc/software-design/README.md](doc/software-design/README.md)  
Flutter project README: [frontend_flutter/README.md](frontend_flutter/README.md)

---

## Architecture

```
SuspensionAndroid/
├── frontend_flutter/   # Flutter/Dart Android app — all processing on-device
└── doc/                # Engineering foundation & software-design documents
```

No backend server. No cloud services. All data is stored locally on the device.

See [frontend_flutter/README.md](frontend_flutter/README.md) for the full layer diagram,
data-flow diagram, and setup instructions.

---

## Workflow

1. **Import** — Pick a DAQ CSV file. Map column names to sensor channels. Select the bike profile.
2. **Calibrate** — Fit front linear calibration from a voltage-sweep. Fit rear linkage polynomial from a stroke-sweep. Manage bike profiles.
3. **Analyze** — Run the signal processing pipeline on the session. View travel histogram, velocity histogram, pitch telemetry, and tuning advisor diagnostics.
4. **Compare** — Select two or more sessions and overlay their histograms.
5. **Simulator** *(debug)* — Generate synthetic DAQ data on-device from 6 physically realistic scenarios — no hardware required.

---

## CSV Format

The logger must produce a CSV with at minimum these columns (names are user-configurable in the Import screen):

| Column | Description |
|--------|-------------|
| `time_s` | Elapsed time in seconds (optional — generated from `fs_hz` if absent) |
| `front_raw` | Front potentiometer ADC count (12-bit integer) |
| `rear_raw` | Rear shock potentiometer ADC count (12-bit integer) |
| `gyro_y_raw` | IMU Y-axis gyroscope (signed int16, pitch rate) |
| `accel_x_raw` | IMU X-axis accelerometer (signed int16, longitudinal) |
| `accel_y_raw` | IMU Y-axis accelerometer (signed int16, lateral) |
| `accel_z_raw` | IMU Z-axis accelerometer (signed int16, vertical) |

Minimum sample rate: **250 Hz**.

---

## Signal Processing Pipeline

```
ADC counts → voltage → displacement (mm) → LPF (20 Hz Butterworth, zero-phase)
           → velocity (backward difference) → travel + velocity histograms

gyro raw → deg/s → bias removal → LPF (10 Hz) → complementary filter (α = 0.98)
         → pitch trace
```

All processing is implemented in pure Dart in `frontend_flutter/lib/data/processing/`.
See [doc/foundation/pitch_angle_report.md](doc/foundation/pitch_angle_report.md) for the
complementary filter derivation.