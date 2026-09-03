import 'app_failure.dart';

/// A repository/use-case return type that forces callers to handle failure
/// explicitly (via `switch`) instead of throwing across architectural
/// boundaries. Kept as a small hand-written sealed class rather than
/// pulling in a functional-programming package — this is the only shape
/// RoamPulse needs from it.
sealed class Result<T> {
  const Result();

  bool get isOk => this is Ok<T>;

  bool get isErr => this is Err<T>;

  R fold<R>(R Function(T value) onOk, R Function(AppFailure failure) onErr) {
    return switch (this) {
      Ok<T>(:final value) => onOk(value),
      Err<T>(:final failure) => onErr(failure),
    };
  }
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final AppFailure failure;
}
