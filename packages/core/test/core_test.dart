import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('Result', () {
    test('Ok reports isOk and folds to the ok branch', () {
      const result = Ok<int>(42);

      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(
        result.fold((v) => 'value: $v', (f) => 'failure: ${f.message}'),
        'value: 42',
      );
    });

    test('Err reports isErr and folds to the err branch', () {
      const result = Err<int>(NotFoundFailure('trip not found'));

      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(
        result.fold((v) => 'value: $v', (f) => 'failure: ${f.message}'),
        'failure: trip not found',
      );
    });

    test('pattern matching narrows the failure type', () {
      const Result<int> result = Err<int>(
        ValidationFailure('bad input', details: {'field': 'email'}),
      );

      final details = switch (result) {
        Ok<int>() => null,
        Err<int>(failure: ValidationFailure(:final details)) => details,
        Err<int>() => null,
      };

      expect(details, {'field': 'email'});
    });
  });
}
