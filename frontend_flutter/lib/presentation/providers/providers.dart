// All Riverpod providers — wire the full dependency graph.
// Single file for simplicity; can be split per domain if it grows.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/bike_storage.dart';
import '../../data/local/session_storage.dart';
import '../../data/repositories/analysis_repository_impl.dart';
import '../../data/repositories/bike_repository_impl.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/entities/analysis_result.dart';
import '../../domain/entities/bike_profile.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/analysis_repository.dart';
import '../../domain/repositories/bike_repository.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/usecases/use_cases.dart';
import '../../core/error/result.dart';

// ---------------------------------------------------------------------------
// Storage layer (singleton)
// ---------------------------------------------------------------------------

final bikeStorageProvider = Provider<BikeStorage>((_) => BikeStorage());
final sessionStorageProvider = Provider<SessionStorage>((_) => SessionStorage());

// ---------------------------------------------------------------------------
// Repository layer
// ---------------------------------------------------------------------------

final bikeRepositoryProvider = Provider<BikeRepository>((ref) =>
    BikeRepositoryImpl(ref.watch(bikeStorageProvider)));

final sessionRepositoryProvider = Provider<SessionRepository>((ref) =>
    SessionRepositoryImpl(ref.watch(sessionStorageProvider)));

final analysisRepositoryProvider = Provider<AnalysisRepository>((ref) =>
    AnalysisRepositoryImpl(
      sessionStorage: ref.watch(sessionStorageProvider),
      bikeStorage: ref.watch(bikeStorageProvider),
    ));

final settingsRepositoryProvider = Provider<SettingsRepository>(
    (_) => SettingsRepositoryImpl());

// ---------------------------------------------------------------------------
// Use case layer
// ---------------------------------------------------------------------------

final getBikesUseCaseProvider = Provider((ref) =>
    GetBikesUseCase(ref.watch(bikeRepositoryProvider)));

final createBikeUseCaseProvider = Provider((ref) =>
    CreateBikeUseCase(ref.watch(bikeRepositoryProvider)));

final updateBikeUseCaseProvider = Provider((ref) =>
    UpdateBikeUseCase(ref.watch(bikeRepositoryProvider)));

final deleteBikeUseCaseProvider = Provider((ref) =>
    DeleteBikeUseCase(ref.watch(bikeRepositoryProvider)));

final getSessionsUseCaseProvider = Provider((ref) =>
    GetSessionsUseCase(ref.watch(sessionRepositoryProvider)));

final createSessionUseCaseProvider = Provider((ref) =>
    CreateSessionUseCase(ref.watch(sessionRepositoryProvider)));

final deleteSessionUseCaseProvider = Provider((ref) =>
    DeleteSessionUseCase(ref.watch(sessionRepositoryProvider)));

final analyzeSessionUseCaseProvider = Provider((ref) =>
    AnalyzeSessionUseCase(
      ref.watch(analysisRepositoryProvider),
      ref.watch(bikeRepositoryProvider),
    ));

final getAnalysisResultUseCaseProvider = Provider((ref) =>
    GetAnalysisResultUseCase(ref.watch(analysisRepositoryProvider)));

final calibrateFrontUseCaseProvider = Provider((ref) =>
    CalibrateFrontUseCase(ref.watch(analysisRepositoryProvider)));

final calibrateRearUseCaseProvider = Provider((ref) =>
    CalibrateRearUseCase(ref.watch(analysisRepositoryProvider)));

final compareSessionsUseCaseProvider = Provider((ref) =>
    CompareSessionsUseCase(ref.watch(analysisRepositoryProvider)));

// ---------------------------------------------------------------------------
// State notifiers
// ---------------------------------------------------------------------------

/// All bike profiles.
final bikesProvider =
    AsyncNotifierProvider<BikesNotifier, List<BikeProfile>>(BikesNotifier.new);

class BikesNotifier extends AsyncNotifier<List<BikeProfile>> {
  @override
  Future<List<BikeProfile>> build() async {
    final result = await ref.read(getBikesUseCaseProvider)();
    return result.fold(
      onSuccess: (bikes) => bikes,
      onFailure: (e) => throw e,
    );
  }

  Future<void> create(BikeProfile bike) async {
    final result = await ref.read(createBikeUseCaseProvider)(bike);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => throw e,
    );
  }

  Future<void> updateBike(String slug, BikeProfile bike) async {
    final result = await ref.read(updateBikeUseCaseProvider)(slug, bike);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => throw e,
    );
  }

  Future<void> delete(String slug) async {
    final result = await ref.read(deleteBikeUseCaseProvider)(slug);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => throw e,
    );
  }
}

/// All sessions.
final sessionsProvider =
    AsyncNotifierProvider<SessionsNotifier, List<Session>>(
        SessionsNotifier.new);

class SessionsNotifier extends AsyncNotifier<List<Session>> {
  @override
  Future<List<Session>> build() async {
    final result = await ref.read(getSessionsUseCaseProvider)();
    return result.fold(
      onSuccess: (s) => s,
      onFailure: (e) => throw e,
    );
  }

  Future<void> create(Session session) async {
    final result = await ref.read(createSessionUseCaseProvider)(session);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => throw e,
    );
  }

  Future<void> delete(String id) async {
    final result = await ref.read(deleteSessionUseCaseProvider)(id);
    result.fold(
      onSuccess: (_) => ref.invalidateSelf(),
      onFailure: (e) => throw e,
    );
  }
}

/// Analysis state — null = not yet analyzed, loading = analyzing.
final analysisProvider = AsyncNotifierProvider.autoDispose
    .family<AnalysisNotifier, AnalysisResult, String>(
        AnalysisNotifier.new);

class AnalysisNotifier
    extends AutoDisposeFamilyAsyncNotifier<AnalysisResult, String> {
  @override
  Future<AnalysisResult> build(String sessionId) async {
    final result =
        await ref.read(getAnalysisResultUseCaseProvider)(sessionId);
    return result.fold(
      onSuccess: (r) => r,
      onFailure: (e) => throw e,
    );
  }

  Future<void> analyze(Session session) async {
    state = const AsyncLoading();
    final result = await ref.read(analyzeSessionUseCaseProvider)(session);
    state = result.fold(
      onSuccess: AsyncData.new,
      onFailure: (e) => AsyncError(e, StackTrace.current),
    );
    if (result.isSuccess) ref.invalidate(sessionsProvider);
  }
}

/// Debug mode toggle.
final debugModeProvider =
    AsyncNotifierProvider<DebugModeNotifier, bool>(DebugModeNotifier.new);

class DebugModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result =
        await ref.read(settingsRepositoryProvider).getDebugMode();
    return result.fold(onSuccess: (v) => v, onFailure: (_) => false);
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? false;
    await ref
        .read(settingsRepositoryProvider)
        .setDebugMode(!current);
    ref.invalidateSelf();
  }
}
