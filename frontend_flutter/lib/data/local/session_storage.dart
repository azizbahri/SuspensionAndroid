import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../core/error/result.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/analysis_result.dart';

/// JSON file-based storage for [Session] metadata and [AnalysisResult] objects.
///
/// Storage layout:
///   <app_documents>/sessions/<uuid>/session.json
///   <app_documents>/sessions/<uuid>/result.json  (if analyzed)
///
/// Mirrors the Python backend:
///   ~/.suspension_study/sessions/<uuid>/session.json
///   ~/.suspension_study/sessions/<uuid>/result.json
class SessionStorage {
  Future<Directory> get _sessionsDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/sessions');
    if (!dir.existsSync()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> _sessionDir(String id) async {
    final base = await _sessionsDir;
    return Directory('${base.path}/$id');
  }

  // ---------------------------------------------------------------------------
  // Sessions
  // ---------------------------------------------------------------------------

  Future<Result<List<Session>>> loadAllSessions() async {
    try {
      final dir = await _sessionsDir;
      final sessions = <Session>[];
      final subdirs = dir
          .listSync()
          .whereType<Directory>()
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final sub in subdirs) {
        final file = File('${sub.path}/session.json');
        if (!file.existsSync()) continue;
        try {
          final json =
              jsonDecode(await file.readAsString()) as Map<String, dynamic>;
          sessions.add(Session.fromJson(json));
        } catch (_) {}
      }
      return Success(sessions);
    } catch (e) {
      return Failure(FileException('Failed to load sessions: $e'));
    }
  }

  Future<Result<Session>> loadSession(String id) async {
    try {
      final dir = await _sessionDir(id);
      final file = File('${dir.path}/session.json');
      if (!file.existsSync()) {
        return Failure(NotFoundException("Session '$id' not found"));
      }
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Success(Session.fromJson(json));
    } catch (e) {
      return Failure(FileException('Failed to load session $id: $e'));
    }
  }

  Future<Result<void>> saveSession(Session session) async {
    try {
      final dir = await _sessionDir(session.id);
      if (!dir.existsSync()) await dir.create(recursive: true);
      final file = File('${dir.path}/session.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(session.toJson()),
      );
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to save session ${session.id}: $e'));
    }
  }

  Future<Result<void>> deleteSession(String id) async {
    try {
      final dir = await _sessionDir(id);
      if (dir.existsSync()) await dir.delete(recursive: true);
      return const Success(null);
    } catch (e) {
      return Failure(FileException('Failed to delete session $id: $e'));
    }
  }

  // ---------------------------------------------------------------------------
  // Analysis results
  // ---------------------------------------------------------------------------

  Future<Result<AnalysisResult>> loadResult(String sessionId) async {
    try {
      final dir = await _sessionDir(sessionId);
      final file = File('${dir.path}/result.json');
      if (!file.existsSync()) {
        return Failure(
            NotFoundException("No result for session '$sessionId'"));
      }
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return Success(AnalysisResult.fromJson(json));
    } catch (e) {
      return Failure(
          FileException('Failed to load result for $sessionId: $e'));
    }
  }

  Future<Result<void>> saveResult(AnalysisResult result) async {
    try {
      final dir = await _sessionDir(result.sessionId);
      if (!dir.existsSync()) await dir.create(recursive: true);
      final file = File('${dir.path}/result.json');
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(result.toJson()),
      );
      return const Success(null);
    } catch (e) {
      return Failure(
          FileException('Failed to save result ${result.sessionId}: $e'));
    }
  }
}
