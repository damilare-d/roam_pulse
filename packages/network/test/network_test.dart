import 'package:core/core.dart';
import 'package:dio/dio.dart';
import 'package:network/network.dart';
import 'package:test/test.dart';

DioException _exception({
  required DioExceptionType type,
  Response<dynamic>? response,
}) {
  final requestOptions = RequestOptions(path: '/api/v1/whatever');
  return DioException(
    requestOptions: requestOptions,
    type: type,
    response: response,
  );
}

Response<dynamic> _response({required int statusCode, Object? data}) {
  return Response(
    requestOptions: RequestOptions(path: '/api/v1/whatever'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  group('mapDioException', () {
    test('maps timeouts to TimeoutFailure', () {
      final failure = mapDioException(
        _exception(type: DioExceptionType.connectionTimeout),
      );
      expect(failure, isA<TimeoutFailure>());
    });

    test('maps connection errors to NetworkUnavailableFailure', () {
      final failure = mapDioException(
        _exception(type: DioExceptionType.connectionError),
      );
      expect(failure, isA<NetworkUnavailableFailure>());
    });

    test(
      'maps a structured NOT_FOUND error body to NotFoundFailure with server message',
      () {
        final response = _response(
          statusCode: 404,
          data: {
            'error': {'code': 'NOT_FOUND', 'message': 'destination not found'},
          },
        );
        final failure = mapDioException(
          _exception(type: DioExceptionType.badResponse, response: response),
        );

        expect(failure, isA<NotFoundFailure>());
        expect(failure.message, 'destination not found');
      },
    );

    test(
      'maps a structured VALIDATION_ERROR body to ValidationFailure with details',
      () {
        final response = _response(
          statusCode: 422,
          data: {
            'error': {
              'code': 'VALIDATION_ERROR',
              'message': 'invalid trip id',
              'details': {'field': 'tripId'},
            },
          },
        );
        final failure = mapDioException(
          _exception(type: DioExceptionType.badResponse, response: response),
        );

        expect(failure, isA<ValidationFailure>());
        expect((failure as ValidationFailure).details, {'field': 'tripId'});
      },
    );

    test(
      'falls back to HTTP status when the body has no recognizable code',
      () {
        final response = _response(statusCode: 503, data: 'not json');
        final failure = mapDioException(
          _exception(type: DioExceptionType.badResponse, response: response),
        );

        expect(failure, isA<ServerFailure>());
      },
    );

    test(
      'falls back to UnknownFailure for an unrecognized status with no body',
      () {
        final response = _response(statusCode: 418);
        final failure = mapDioException(
          _exception(type: DioExceptionType.badResponse, response: response),
        );

        expect(failure, isA<UnknownFailure>());
      },
    );
  });
}
