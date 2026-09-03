import 'package:core/core.dart';
import 'package:dio/dio.dart';

/// Maps a [DioException] to RoamPulse's [AppFailure] hierarchy. Bad
/// responses are matched against the backend's structured error codes
/// first (see backend/api/internal/apperror) and fall back to the raw
/// HTTP status if the body doesn't carry one — the client never collapses
/// every failure into "something went wrong" (docs/ARCHITECTURE.md
/// section 10).
AppFailure mapDioException(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const TimeoutFailure();
    case DioExceptionType.connectionError:
      return const NetworkUnavailableFailure();
    case DioExceptionType.badCertificate:
      return const NetworkUnavailableFailure('Secure connection failed.');
    case DioExceptionType.cancel:
      return const UnknownFailure('The request was cancelled.');
    case DioExceptionType.badResponse:
      return _mapBadResponse(exception.response);
    case DioExceptionType.unknown:
      return const NetworkUnavailableFailure();
  }
}

AppFailure _mapBadResponse(Response<dynamic>? response) {
  final body = response?.data;
  String? code;
  String? message;
  Map<String, dynamic>? details;

  if (body is Map<String, dynamic>) {
    final error = body['error'];
    if (error is Map<String, dynamic>) {
      code = error['code'] as String?;
      message = error['message'] as String?;
      final rawDetails = error['details'];
      if (rawDetails is Map<String, dynamic>) {
        details = rawDetails;
      }
    }
  }

  switch (code) {
    case 'NOT_FOUND':
      return NotFoundFailure(message ?? "We couldn't find that.");
    case 'VALIDATION_ERROR':
      return ValidationFailure(message ?? 'Invalid request.', details: details);
    case 'UNAUTHORIZED':
      return UnauthorizedFailure(
        message ?? 'You are not authorized to do that.',
      );
    case 'SERVICE_UNAVAILABLE':
      return ServerFailure(message ?? 'The server is temporarily unavailable.');
  }

  final status = response?.statusCode;
  return switch (status) {
    401 => const UnauthorizedFailure(),
    404 => const NotFoundFailure(),
    422 => ValidationFailure(message ?? 'Invalid request.', details: details),
    503 => const ServerFailure(),
    int s when s >= 500 => const ServerFailure(),
    _ => const UnknownFailure(),
  };
}
