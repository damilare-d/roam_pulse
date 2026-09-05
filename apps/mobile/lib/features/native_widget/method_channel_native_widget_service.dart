import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'connectivity_widget_data.dart';
import 'native_widget_service.dart';
import 'plan_widget_data.dart';

/// Thin platform-channel shell — deliberately untested beyond channel
/// wiring, mirroring ChaosInterceptor (Phase 9): the payload types it
/// sends are what's actually unit-tested. No-ops on any platform other
/// than Android/iOS, since a desktop/web dev run has no widget host to
/// talk to and would otherwise throw a MissingPluginException.
class MethodChannelNativeWidgetService implements NativeWidgetService {
  MethodChannelNativeWidgetService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.roampulse.widget');

  final MethodChannel _channel;

  bool get _supportsWidgets =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<void> updateConnectivity(ConnectivityWidgetData data) async {
    if (!_supportsWidgets) return;
    await _channel.invokeMethod('updateConnectivity', data.toJson());
  }

  @override
  Future<void> updatePlan(PlanWidgetData data) async {
    if (!_supportsWidgets) return;
    await _channel.invokeMethod('updatePlan', data.toJson());
  }
}
