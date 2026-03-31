import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error/result.dart';
import '../../domain/repositories/settings_repository.dart';

/// SharedPreferences-backed implementation of [SettingsRepository].
class SettingsRepositoryImpl implements SettingsRepository {
  static const _keyDefaultBike = 'default_bike_slug';
  static const _keyDebugMode = 'debug_mode';

  @override
  Future<Result<String?>> getDefaultBikeSlug() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getString(_keyDefaultBike));
    } catch (e) {
      return Failure(FileException('Failed to load settings: $e'));
    }
  }

  @override
  Future<Result<void>> setDefaultBikeSlug(String slug) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyDefaultBike, slug);
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to save settings: $e'));
    }
  }

  @override
  Future<Result<bool>> getDebugMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return Success(prefs.getBool(_keyDebugMode) ?? false);
    } catch (e) {
      return Failure(FileException('Failed to load settings: $e'));
    }
  }

  @override
  Future<Result<void>> setDebugMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDebugMode, enabled);
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to save settings: $e'));
    }
  }
}
