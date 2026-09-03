/// RoamPulse's classified failure hierarchy (see docs/ARCHITECTURE.md
/// section 10 / docs/PRODUCT_DISCOVERY.md "error handling"). Repositories
/// and the network layer never throw raw exceptions across their boundary
/// — everything becomes one of these, so the UI can render a specific,
/// honest state instead of a generic "something went wrong".
sealed class AppFailure {
  const AppFailure(this.message);

  final String message;
}

final class NetworkUnavailableFailure extends AppFailure {
  const NetworkUnavailableFailure([super.message = 'No internet connection.']);
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure([super.message = 'The request timed out.']);
}

final class ServerFailure extends AppFailure {
  const ServerFailure([
    super.message = 'The server is temporarily unavailable.',
  ]);
}

final class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure([
    super.message = 'You are not authorized to do that.',
  ]);
}

final class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {this.details});

  final Map<String, dynamic>? details;
}

final class NotFoundFailure extends AppFailure {
  const NotFoundFailure([super.message = "We couldn't find that."]);
}

final class CacheFailure extends AppFailure {
  const CacheFailure([super.message = 'Cached data is unavailable.']);
}

final class ParsingFailure extends AppFailure {
  const ParsingFailure([super.message = 'Received an unexpected response.']);
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
