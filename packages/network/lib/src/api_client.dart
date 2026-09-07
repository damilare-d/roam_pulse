import 'package:core/core.dart';
import 'package:dio/dio.dart';

import 'api_config.dart';
import 'dio_error_mapper.dart';

/// Thin wrapper around Dio that unwraps RoamPulse's response envelope
/// (`{data, meta}` / `{error: {code, message, details}}`, see
/// docs/ARCHITECTURE.md section 7) into a [Result], so repositories never
/// touch Dio or raw JSON directly.
class ApiClient {
  ApiClient({required ApiConfig config, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: config.baseUrl,
              connectTimeout: config.connectTimeout,
              receiveTimeout: config.receiveTimeout,
            ),
          ) {
    if (config.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  final Dio _dio;

  /// Attaches an extra interceptor (e.g. Chaos Mode's fault injector,
  /// Phase 9) without exposing the underlying [Dio] instance itself —
  /// callers still can't reach into request internals beyond adding
  /// interceptors through this one seam.
  void addInterceptor(Interceptor interceptor) =>
      _dio.interceptors.add(interceptor);

  /// GETs [path] and decodes the `data` object of the envelope with
  /// [fromJson]. Use for endpoints that return a single JSON object
  /// (profile, trips/current, plans/current, ...).
  Future<Result<T>> getJson<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final data = response.data?['data'];
      if (data is! Map<String, dynamic>) {
        return const Err(ParsingFailure());
      }
      return Ok(fromJson(data));
    } on DioException catch (e) {
      return Err(mapDioException(e));
    } on TypeError {
      return const Err(ParsingFailure());
    }
  }

  /// POSTs [data] to [path] and decodes the `data` object of the response
  /// envelope with [fromJson]. [receiveTimeout] overrides the client's
  /// configured default for this one call — most endpoints are fast
  /// Postgres reads well within the default, but a genuine Claude
  /// round-trip (the AI recovery endpoint) routinely takes longer than
  /// the 10s sized for everything else.
  Future<Result<T>> postJson<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Object? data,
    Duration? receiveTimeout,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        options: receiveTimeout == null
            ? null
            : Options(receiveTimeout: receiveTimeout),
      );
      final responseData = response.data?['data'];
      if (responseData is! Map<String, dynamic>) {
        return const Err(ParsingFailure());
      }
      return Ok(fromJson(responseData));
    } on DioException catch (e) {
      return Err(mapDioException(e));
    } on TypeError {
      return const Err(ParsingFailure());
    }
  }

  /// GETs [path] and decodes the `data` array of the envelope with
  /// [fromJson] applied element-wise. Use for list endpoints
  /// (connectivity/events, ...).
  Future<Result<List<T>>> getJsonList<T>(
    String path, {
    required T Function(Map<String, dynamic> json) fromJson,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      final data = response.data?['data'];
      if (data is! List) {
        return const Err(ParsingFailure());
      }
      return Ok(data.map((e) => fromJson(e as Map<String, dynamic>)).toList());
    } on DioException catch (e) {
      return Err(mapDioException(e));
    } on TypeError {
      return const Err(ParsingFailure());
    }
  }
}
