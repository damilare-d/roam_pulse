import 'package:dio/dio.dart';

import 'chaos_action.dart';
import 'chaos_mode_controller.dart';

/// Thin Dio [Interceptor] that reads the current dials off
/// [ChaosModeController], asks the pure [decideChaosAction] what to do,
/// and translates the answer into Dio's request-handler calls. Deliberately
/// not unit-tested itself — the decision logic it defers to already is
/// (chaos_action_test.dart); this class only has to get the translation
/// right, which live testing covers.
class ChaosInterceptor extends Interceptor {
  ChaosInterceptor(this._controller);

  final ChaosModeController _controller;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final action = decideChaosAction(
      network: _controller.network,
      api: _controller.api,
    );
    switch (action) {
      case ChaosPassThrough():
        handler.next(options);
      case ChaosDelay(:final duration):
        Future.delayed(duration, () => handler.next(options));
      case ChaosRejectOffline():
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
            message: 'Chaos Mode: offline',
          ),
        );
      case ChaosRejectTimeout():
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.connectionTimeout,
            message: 'Chaos Mode: timeout',
          ),
        );
      case ChaosRejectServerError():
        handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            message: 'Chaos Mode: server error',
            response: Response(
              requestOptions: options,
              statusCode: 500,
              data: {
                'error': {
                  'code': 'SERVICE_UNAVAILABLE',
                  'message': 'Chaos Mode: simulated server error',
                },
              },
            ),
          ),
        );
      case ChaosResolveEmpty():
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: <String, dynamic>{},
          ),
        );
    }
  }
}
