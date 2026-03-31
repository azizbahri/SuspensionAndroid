import '../../core/error/result.dart';

/// Abstract contract for app-level settings persistence.
abstract interface class SettingsRepository {
  Future<Result<String?>> getDefaultBikeSlug();
  Future<Result<void>> setDefaultBikeSlug(String slug);
  Future<Result<bool>> getDebugMode();
  Future<Result<void>> setDebugMode(bool enabled);
}
