# Suspension DAQ Documentation

This folder is split into two layers:

- the theoretical foundation of the suspension-analysis framework,
- software-design documents that describe how the framework is implemented in the Flutter Android application.

## Start Here

- [foundation/overview.md](foundation/overview.md): Main DAQ framework, equations, graph definitions, and tuning workflow

## Foundation Documents

- [foundation/README.md](foundation/README.md): Entry point for the theory and analysis foundation notes
- [foundation/index.md](foundation/index.md): Foundation index and reading order
- [foundation/overview.md](foundation/overview.md): Main DAQ framework, equations, graph definitions, and tuning workflow
- [foundation/hardware_measurement_report.md](foundation/hardware_measurement_report.md): Hardware architecture, sensor roles, required measurements, ADC resolution, and logger sample-rate reasoning
- [foundation/displacement_translation_report.md](foundation/displacement_translation_report.md): Front and rear displacement translation, calibration constants, and rear-linkage fitting
- [foundation/velocity_calculation_report.md](foundation/velocity_calculation_report.md): Numerical differentiation, filtering, DAQ implementation, and wheel-versus-shaft velocity
- [foundation/pitch_angle_report.md](foundation/pitch_angle_report.md): Gyroscope integration, bias control, numerical integration, and pitch-angle drift
- [foundation/graphical_analysis_report.md](foundation/graphical_analysis_report.md): Travel histogram, velocity histogram, telemetry trace, and axis formulas
- [foundation/spring_rate_preload_report.md](foundation/spring_rate_preload_report.md): Using Graph 1 to distinguish preload errors from spring-rate errors
- [foundation/compression_damping_report.md](foundation/compression_damping_report.md): Using the compression side of Graph 2 to diagnose harshness and brake dive
- [foundation/rebound_damping_report.md](foundation/rebound_damping_report.md): Using the rebound side of Graph 2 and telemetry to diagnose packing and pogo behavior

## Software Design

- [software-design/README.md](software-design/README.md): Flutter app architecture — layer diagram, data flow, hardware abstraction, simulator

## Suggested Reading Order

1. [foundation/overview.md](foundation/overview.md)
2. [foundation/hardware_measurement_report.md](foundation/hardware_measurement_report.md)
3. [foundation/displacement_translation_report.md](foundation/displacement_translation_report.md)
4. [foundation/velocity_calculation_report.md](foundation/velocity_calculation_report.md)
5. [foundation/pitch_angle_report.md](foundation/pitch_angle_report.md)
6. [foundation/graphical_analysis_report.md](foundation/graphical_analysis_report.md)
7. [foundation/spring_rate_preload_report.md](foundation/spring_rate_preload_report.md)
8. [foundation/compression_damping_report.md](foundation/compression_damping_report.md)
9. [foundation/rebound_damping_report.md](foundation/rebound_damping_report.md)

## Software Reading Path

1. [software-design/README.md](software-design/README.md): Flutter architecture overview