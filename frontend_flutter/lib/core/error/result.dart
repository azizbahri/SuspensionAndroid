/// Sealed Result type for error propagation without exceptions crossing layer boundaries.
///
/// Every repository method and use case returns [Result<T>] so callers cannot
/// accidentally ignore a failure case. The UI layer maps [AppException] sub-types
/// to human-readable strings.
sealed class Result<T> {
  const Result();

  /// Transform the result by applying [onSuccess] or [onFailure].
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  });

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T get dataOrThrow {
    final self = this;
    if (self is Success<T>) return self.data;
    throw (self as Failure<T>).exception;
  }

  AppException get exceptionOrThrow {
    final self = this;
    if (self is Failure<T>) return self.exception;
    throw StateError('Result is Success, not Failure');
  }
}

/// Successful result carrying [data].
final class Success<T> extends Result<T> {
  const Success(this.data);

  final T data;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  }) =>
      onSuccess(data);

  @override
  String toString() => 'Success($data)';
}

/// Failed result carrying an [exception].
final class Failure<T> extends Result<T> {
  const Failure(this.exception);

  final AppException exception;

  @override
  R fold<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException exception) onFailure,
  }) =>
      onFailure(exception);

  @override
  String toString() => 'Failure(${exception.message})';
}

// ---------------------------------------------------------------------------
// AppException hierarchy — import separately or keep co-located for convenience.
// ---------------------------------------------------------------------------

/// Base class for all application exceptions.
/// Every sub-class corresponds to a user-explainable failure category.
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// I/O error reading or writing a local file.
final class FileException extends AppException {
  const FileException(super.message);
}

/// JSON parse error (stored data or CSV parse error).
final class ParseException extends AppException {
  const ParseException([super.message = 'Failed to parse data']);
}

/// Business-rule validation failed before any I/O was attempted.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Signal processing failed (e.g., insufficient data for filter).
final class ProcessingException extends AppException {
  const ProcessingException(super.message);
}

/// Requested entity was not found in local storage.
final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}

/// Hardware source is unavailable or not yet implemented.
final class HardwareException extends AppException {
  const HardwareException([super.message = 'Hardware source not available']);
}

/// Simulator failed to generate data.
final class SimulatorException extends AppException {
  const SimulatorException(super.message);
}
