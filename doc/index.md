# Suspension DAQ Documentation Index

This directory contains three categories of material:

- theoretical notes that define the measurement, signal-processing, and tuning framework,
- software-design notes that describe applications built on that framework,
- implementation-facing notes that describe how the product should actually be assembled.

## Primary Document

- [foundation/overview.md](foundation/overview.md): Main DAQ framework, equations, and interpretation workflow for suspension tuning.

## Supporting Technical Notes

- [foundation/README.md](foundation/README.md): Entry point for the theory and analysis foundation notes.
- [foundation/index.md](foundation/index.md): Foundation index and reading order.
- [foundation/hardware_measurement_report.md](foundation/hardware_measurement_report.md): Detailed explanation of the DAQ hardware stack, required measurements, ADC resolution, IMU ranges, and logger sample-rate requirements.
- [foundation/displacement_translation_report.md](foundation/displacement_translation_report.md): Detailed derivation of front and rear displacement translation, calibration constants, and rear-linkage polynomial fitting.
- [foundation/velocity_calculation_report.md](foundation/velocity_calculation_report.md): Detailed explanation of numerical differentiation, filtering, DAQ implementation, and wheel-versus-shaft velocity interpretation.
- [foundation/pitch_angle_report.md](foundation/pitch_angle_report.md): Detailed explanation of gyroscope integration, bias control, numerical integration, and pitch-angle drift management.
- [foundation/graphical_analysis_report.md](foundation/graphical_analysis_report.md): Detailed explanation of the travel histogram, velocity histogram, telemetry trace, and the axis formulas used to construct them.
- [foundation/spring_rate_preload_report.md](foundation/spring_rate_preload_report.md): Detailed explanation of how Graph 1 distinguishes preload errors from spring-rate errors, with interpretation logic and worked examples.
- [foundation/compression_damping_report.md](foundation/compression_damping_report.md): Detailed explanation of how the compression side of Graph 2 is used to diagnose harshness, brake dive, and low-speed versus high-speed compression behavior.
- [foundation/rebound_damping_report.md](foundation/rebound_damping_report.md): Detailed explanation of how the rebound side of Graph 2 and telemetry are used to diagnose packing, pogo behavior, and rebound-damping balance.

## Software Design Notes

- [software-design/README.md](software-design/README.md): Flutter app architecture — layer diagram, data flow, hardware abstraction, and simulator design.

## Recommended Reading Order

1. [foundation/overview.md](foundation/overview.md)
2. [foundation/hardware_measurement_report.md](foundation/hardware_measurement_report.md)
3. [foundation/displacement_translation_report.md](foundation/displacement_translation_report.md)
4. [foundation/velocity_calculation_report.md](foundation/velocity_calculation_report.md)
5. [foundation/pitch_angle_report.md](foundation/pitch_angle_report.md)
6. [foundation/graphical_analysis_report.md](foundation/graphical_analysis_report.md)
7. [foundation/spring_rate_preload_report.md](foundation/spring_rate_preload_report.md)
8. [foundation/compression_damping_report.md](foundation/compression_damping_report.md)
9. [foundation/rebound_damping_report.md](foundation/rebound_damping_report.md)

## Software Reading Order

1. [software-design/README.md](software-design/README.md)