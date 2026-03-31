import 'dart:math' as math;
import 'dart:typed_data';

import '../processing/signal_filter.dart';

/// Container for true physical state arrays produced by [PhysicsModel].
///
/// Mirrors the Python backend StateDict dataclass.
class StateDict {
  const StateDict({
    required this.t,
    required this.wFrontTrue,
    required this.wRearTrue,
    required this.sRearTrue,
    required this.phiTrue,
    required this.omegaYTrue,
    required this.accelXTrue,
    required this.accelYTrue,
    required this.accelZTrue,
  });

  final Float64List t; // time [s]
  final Float64List wFrontTrue; // front wheel travel [mm]
  final Float64List wRearTrue; // rear wheel travel [mm]
  final Float64List sRearTrue; // rear shock stroke [mm]
  final Float64List phiTrue; // chassis pitch [deg]
  final Float64List omegaYTrue; // pitch rate [deg/s]
  final Float64List accelXTrue; // longitudinal accel [m/s²]
  final Float64List accelYTrue; // lateral accel [m/s²]
  final Float64List accelZTrue; // vertical accel [m/s²]

  int get length => t.length;
}

/// Forward model of physical motorcycle states for each simulation scenario.
///
/// Port of backend/app/simulator/physics.py → PhysicsModel + _invert_linkage.
///
/// Supports 6 scenarios:
///   staticSag, brakingEvent, squareEdgeHit, repeatedBumps, jumpAndLanding,
///   roughTerrain
class PhysicsModel {
  PhysicsModel({
    this.fsHz = 250.0,
    this.durationS = 10.0,
    this.linkageA = -0.015,
    this.linkageB = 4.20,
    this.linkageC = 0.0,
    this.g = 9.80665,
  }) {
    _n = (durationS * fsHz).round();
    _dt = 1.0 / fsHz;
    _t = Float64List(_n);
    for (int i = 0; i < _n; i++) {
      _t[i] = i * _dt;
    }
  }

  final double fsHz;
  final double durationS;
  final double linkageA;
  final double linkageB;
  final double linkageC;
  final double g;

  late final int _n;
  late final double _dt;
  late final Float64List _t;

  // ---------------------------------------------------------------------------
  // Linkage inversion
  // ---------------------------------------------------------------------------

  /// Invert W = a·s² + b·s + c → s (positive root of the quadratic).
  Float64List _invertLinkage(Float64List wMm) {
    final s = Float64List(_n);
    for (int i = 0; i < _n; i++) {
      final disc = math.max(
        0.0,
        linkageB * linkageB - 4.0 * linkageA * (linkageC - wMm[i]),
      );
      s[i] = (-linkageB + math.sqrt(disc)) / (2.0 * linkageA);
    }
    return s;
  }

  // ---------------------------------------------------------------------------
  // Scenario helpers
  // ---------------------------------------------------------------------------

  Float64List _zeros() => Float64List(_n);

  Float64List _full(double value) {
    final arr = Float64List(_n);
    arr.fillRange(0, _n, value);
    return arr;
  }

  Float64List _clip(Float64List arr, double lo, double hi) {
    for (int i = 0; i < arr.length; i++) {
      if (arr[i] < lo) arr[i] = lo;
      if (arr[i] > hi) arr[i] = hi;
    }
    return arr;
  }

  // ---------------------------------------------------------------------------
  // Scenario 1: Static sag
  // ---------------------------------------------------------------------------

  /// Bike stationary at sag. Pitch=0, accel=(0,0,g).
  StateDict staticSag({
    double wFrontMm = 70.0,
    double wRearMm = 95.0,
  }) {
    final wF = _full(wFrontMm);
    final wR = _full(wRearMm);
    final sR = _invertLinkage(wR);
    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: _zeros(),
      omegaYTrue: _zeros(),
      accelXTrue: _zeros(),
      accelYTrue: _zeros(),
      accelZTrue: _full(g),
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario 2: Hard braking
  // ---------------------------------------------------------------------------

  /// Hard braking: sinusoidal deceleration, fork compresses, nose-down pitch.
  StateDict brakingEvent({
    double peakDecelG = 0.8,
    double eventDurationS = 2.0,
    double forkCompressionMm = 40.0,
  }) {
    final tCenter =
        math.min(eventDurationS * 0.5, durationS * 0.3);
    final tSigma = eventDurationS * 0.3;

    final ax = Float64List(_n);
    final wF = Float64List(_n);
    final wR = Float64List(_n);
    final omega = Float64List(_n);

    for (int i = 0; i < _n; i++) {
      final ti = _t[i];
      final diff = ti - tCenter;
      final gauss = peakDecelG * math.exp(-0.5 * diff * diff / (tSigma * tSigma));
      ax[i] = -gauss * g;
      wF[i] = 70.0 + forkCompressionMm * (gauss / peakDecelG);
      final rearPct = gauss / peakDecelG;
      wR[i] = math.max(5.0, 95.0 - 10.0 * rearPct);
      omega[i] = -peakDecelG *
          40.0 *
          math.exp(-0.5 * diff * diff / (tSigma * tSigma));
    }

    // Integrate pitch
    final phi = _zeros();
    for (int i = 1; i < _n; i++) {
      phi[i] = phi[i - 1] + 0.5 * (omega[i] + omega[i - 1]) * _dt;
    }

    final sR = _invertLinkage(wR);
    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: phi,
      omegaYTrue: omega,
      accelXTrue: ax,
      accelYTrue: _zeros(),
      accelZTrue: _full(g),
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario 3: Square-edge hit
  // ---------------------------------------------------------------------------

  /// Sharp square-edge impact: fast compression, exponential rebound.
  StateDict squareEdgeHit({
    double impactDurationS = 0.012,
    double peakCompressionMm = 60.0,
    double reboundTimeConstantS = 0.25,
  }) {
    final tImpact = durationS * 0.2;
    final wF = Float64List(_n);
    for (int i = 0; i < _n; i++) {
      final ti = _t[i];
      if (ti < tImpact) {
        wF[i] = 70.0;
      } else if (ti < tImpact + impactDurationS) {
        final frac = (ti - tImpact) / impactDurationS;
        wF[i] = 70.0 + peakCompressionMm * frac;
      } else {
        wF[i] = 70.0 +
            peakCompressionMm *
                math.exp(
                    -(ti - tImpact - impactDurationS) / reboundTimeConstantS);
      }
    }
    final wR = _full(95.0);
    final sR = _invertLinkage(wR);
    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: _zeros(),
      omegaYTrue: _zeros(),
      accelXTrue: _zeros(),
      accelYTrue: _zeros(),
      accelZTrue: _full(g),
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario 4: Repeated bumps
  // ---------------------------------------------------------------------------

  /// Successive bumps with slow rebound → cumulative packing.
  StateDict repeatedBumps({
    int nBumps = 8,
    double bumpSpacingS = 0.8,
    double peakMm = 50.0,
    double reboundDampingFactor = 0.85,
  }) {
    final wF = _full(70.0);
    final wR = _full(95.0);
    final compDur = 0.040;
    final rebTau = bumpSpacingS * reboundDampingFactor;

    for (int k = 0; k < nBumps; k++) {
      final tHit = 0.5 + k * bumpSpacingS;
      for (int i = 0; i < _n; i++) {
        final ti = _t[i];
        if (ti < tHit) continue;
        final dtSince = ti - tHit;
        double extra;
        if (dtSince < compDur) {
          extra = peakMm * dtSince / compDur;
        } else {
          extra = peakMm * math.exp(-(dtSince - compDur) / rebTau);
        }
        wF[i] += extra;
        wR[i] += extra * 0.5;
      }
    }
    _clip(wF, 0.0, 200.0);
    _clip(wR, 0.0, 200.0);
    final sR = _invertLinkage(wR);
    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: _zeros(),
      omegaYTrue: _zeros(),
      accelXTrue: _zeros(),
      accelYTrue: _zeros(),
      accelZTrue: _full(g),
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario 5: Jump and landing
  // ---------------------------------------------------------------------------

  /// Both wheels extend mid-air, large landing compression on front.
  StateDict jumpAndLanding({
    double airtimeS = 1.2,
    double landingCompressionMm = 120.0,
  }) {
    final tLaunch = 1.0;
    final tLand = tLaunch + airtimeS;
    const landDur = 0.020;

    final wF = Float64List(_n);
    final az = Float64List(_n);

    for (int i = 0; i < _n; i++) {
      final ti = _t[i];
      if (ti < tLaunch) {
        wF[i] = 70.0;
        az[i] = g;
      } else if (ti < tLand) {
        wF[i] = 15.0;
        az[i] = 0.05 * g;
      } else if (ti < tLand + landDur) {
        final frac = (ti - tLand) / landDur;
        wF[i] = 15.0 + landingCompressionMm * frac;
        az[i] = g + 8.0 * g * frac;
      } else {
        final decay = math.exp(-(ti - tLand - landDur) / 0.3);
        wF[i] = 15.0 + landingCompressionMm * decay;
        az[i] = g;
      }
    }

    final wR = _full(95.0);
    final sR = _invertLinkage(wR);
    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: _zeros(),
      omegaYTrue: _zeros(),
      accelXTrue: _zeros(),
      accelYTrue: _zeros(),
      accelZTrue: az,
    );
  }

  // ---------------------------------------------------------------------------
  // Scenario 6: Rough terrain (band-limited Gaussian noise)
  // ---------------------------------------------------------------------------

  /// Band-limited Gaussian random travel for stochastic rough-terrain simulation.
  StateDict roughTerrain({
    double rmsFrontMm = 25.0,
    double rmsRearMm = 20.0,
    int seed = 42,
  }) {
    final rng = math.Random(seed);

    Float64List bandLimited(double rms, {double fcHz = 15.0}) {
      // Generate standard Gaussian noise
      final noise = Float64List(_n);
      for (int i = 0; i < _n; i++) {
        noise[i] = _nextGaussian(rng);
      }
      // Apply Butterworth LPF to band-limit
      final (:b, :a) = SignalFilter.butter(fcHz, fsHz);
      final filtered = SignalFilter.filtfilt(noise, b, a);
      // Normalise to target RMS
      double sum = 0;
      for (final v in filtered) sum += v * v;
      final std = math.sqrt(sum / filtered.length);
      final scale = std < 1e-12 ? 1.0 : rms / std;
      return Float64List.fromList(filtered.map((v) => v * scale).toList());
    }

    final wF = bandLimited(rmsFrontMm);
    final wR = bandLimited(rmsRearMm);
    for (int i = 0; i < _n; i++) {
      wF[i] = wF[i] + 70.0;
      wR[i] = wR[i] + 95.0;
    }
    _clip(wF, 0.0, 200.0);
    _clip(wR, 0.0, 200.0);
    final sR = _invertLinkage(wR);

    return StateDict(
      t: Float64List.fromList(_t),
      wFrontTrue: wF,
      wRearTrue: wR,
      sRearTrue: sR,
      phiTrue: _zeros(),
      omegaYTrue: _zeros(),
      accelXTrue: _zeros(),
      accelYTrue: _zeros(),
      accelZTrue: _full(g),
    );
  }

  // ---------------------------------------------------------------------------
  // Gaussian random number via Box-Muller transform
  // ---------------------------------------------------------------------------

  static double _nextGaussian(math.Random rng) {
    double u1;
    do {
      u1 = rng.nextDouble();
    } while (u1 == 0.0);
    final u2 = rng.nextDouble();
    return math.sqrt(-2.0 * math.log(u1)) *
        math.cos(2.0 * math.pi * u2);
  }
}
