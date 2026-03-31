import '../../core/error/result.dart';
import '../entities/session.dart';

/// Abstract contract for session persistence.
abstract interface class SessionRepository {
  Future<Result<List<Session>>> getSessions();
  Future<Result<Session>> createSession(Session session);
  Future<Result<Session>> updateSession(Session session);
  Future<Result<void>> deleteSession(String id);
  Future<Result<Session>> getSession(String id);
}
