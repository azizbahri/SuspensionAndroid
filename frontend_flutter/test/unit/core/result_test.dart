import 'package:flutter_test/flutter_test.dart';

import '../../../lib/core/error/result.dart';

// ValidationException is used as a concrete AppException test double.
// AppException is sealed and cannot be sub-classed outside its own library.
const _testException = ValidationException('test error');

void main() {
  group('Result<T>', () {
    test('Success.isSuccess is true', () {
      const r = Success<int>(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
    });

    test('Failure.isFailure is true', () {
      const r = Failure<int>(_testException);
      expect(r.isFailure, isTrue);
      expect(r.isSuccess, isFalse);
    });

    test('Success.dataOrThrow returns data', () {
      const r = Success<String>('hello');
      expect(r.dataOrThrow, 'hello');
    });

    test('Failure.dataOrThrow throws the exception', () {
      const r = Failure<String>(_testException);
      expect(() => r.dataOrThrow, throwsA(isA<AppException>()));
    });

    test('Success.fold calls onSuccess', () {
      const r = Success<int>(7);
      final out = r.fold(onSuccess: (d) => d * 2, onFailure: (_) => 0);
      expect(out, 14);
    });

    test('Failure.fold calls onFailure', () {
      const r = Failure<int>(_testException);
      final out = r.fold(
          onSuccess: (_) => 'ok', onFailure: (e) => e.message);
      expect(out, 'test error');
    });
  });

  group('AppException subclasses', () {
    test('FileException carries message', () {
      const e = FileException('disk full');
      expect(e.message, 'disk full');
      expect(e.toString(), 'disk full');
    });

    test('ValidationException is sealed subclass', () {
      const e = ValidationException('required');
      expect(e, isA<AppException>());
    });

    test('NotFoundException is sealed subclass', () {
      const e = NotFoundException('not found');
      expect(e, isA<AppException>());
    });
  });
}
