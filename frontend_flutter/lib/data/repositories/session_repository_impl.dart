import '../../core/error/result.dart';
import '../../data/local/session_storage.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';

/// Concrete implementation of [SessionRepository] backed by [SessionStorage].
class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._storage);
  final SessionStorage _storage;

  @override
  Future<Result<List<Session>>> getSessions() => _storage.loadAllSessions();

  @override
  Future<Result<Session>> getSession(String id) => _storage.loadSession(id);

  @override
  Future<Result<Session>> createSession(Session session) async {
    final saved = await _storage.saveSession(session);
    return saved.fold(
      onSuccess: (_) => Success(session),
      onFailure: Failure.new,
    );
  }

  @override
  Future<Result<Session>> updateSession(Session session) async {
    final saved = await _storage.saveSession(session);
    return saved.fold(
      onSuccess: (_) => Success(session),
      onFailure: Failure.new,
    );
  }

  @override
  Future<Result<void>> deleteSession(String id) =>
      _storage.deleteSession(id);
}
