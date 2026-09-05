import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/native_widget/connectivity_widget_data.dart';
import 'package:roam_pulse/features/native_widget/method_channel_native_widget_service.dart';
import 'package:roam_pulse/features/native_widget/plan_widget_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.roampulse.widget');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'invokes updateConnectivity on Android with the serialized payload',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final service = MethodChannelNativeWidgetService(channel: channel);

      await service.updateConnectivity(
        ConnectivityWidgetData(
          state: 'connected',
          carrierName: 'SoftBank',
          technology: '5G',
          lastSyncedAt: DateTime.utc(2026, 9, 4),
        ),
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'updateConnectivity');
      expect(calls.single.arguments['state'], 'connected');
    },
  );

  test('invokes updatePlan on iOS with the serialized payload', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final service = MethodChannelNativeWidgetService(channel: channel);

    await service.updatePlan(
      const PlanWidgetData(
        destinationCity: 'Tokyo',
        countryCode: 'JP',
        dataRemainingMb: 100,
        dataAllowanceMb: 200,
        daysRemaining: 2,
      ),
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'updatePlan');
  });

  test('does nothing on a platform without a widget host', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final service = MethodChannelNativeWidgetService(channel: channel);

    await service.updateConnectivity(
      ConnectivityWidgetData(
        state: 'connected',
        carrierName: 'SoftBank',
        technology: '5G',
        lastSyncedAt: DateTime.utc(2026, 9, 4),
      ),
    );

    expect(calls, isEmpty);
  });
}
