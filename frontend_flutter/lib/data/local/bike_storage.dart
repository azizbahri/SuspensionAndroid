import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/error/result.dart';
import '../../domain/entities/bike_profile.dart';

/// JSON file-based storage for [BikeProfile] objects.
///
/// Storage layout:
///   <app_documents>/bikes/<slug>.json
///
/// Mirrors the Python backend structure:
///   ~/.suspension_study/bikes/<slug>.json
class BikeStorage {
  Future<Directory> get _dir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/bikes');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> _file(String slug) async {
    final d = await _dir;
    return File('${d.path}/$slug.json');
  }

  Future<Result<List<BikeProfile>>> loadAll() async {
    try {
      final dir = await _dir;
      final bikes = <BikeProfile>[];
      final entities = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final file in entities) {
        try {
          final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          bikes.add(BikeProfile.fromJson(json));
        } catch (_) {
          // Skip malformed files, same as Python backend
        }
      }
      return Success(bikes);
    } catch (e) {
      return Failure(FileException('Failed to load bike profiles: $e'));
    }
  }

  Future<Result<BikeProfile>> load(String slug) async {
    try {
      final file = await _file(slug);
      if (!file.existsSync()) {
        return Failure(NotFoundException("Bike '$slug' not found"));
      }
      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Success(BikeProfile.fromJson(json));
    } catch (e) {
      return Failure(FileException('Failed to load bike $slug: $e'));
    }
  }

  Future<Result<void>> save(BikeProfile bike) async {
    try {
      final file = await _file(bike.slug);
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(bike.toJson()),
      );
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to save bike ${bike.slug}: $e'));
    }
  }

  Future<Result<void>> delete(String slug) async {
    try {
      final file = await _file(slug);
      if (file.existsSync()) await file.delete();
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to delete bike $slug: $e'));
    }
  }

  /// Seed the default T7 profile if no bikes exist yet.
  Future<void> seedDefaults() async {
    final result = await loadAll();
    if (result is Success<List<BikeProfile>> && result.data.isEmpty) {
      await save(BikeProfile.t7);
    }
  }
}
