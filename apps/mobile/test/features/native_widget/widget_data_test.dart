import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/native_widget/connectivity_widget_data.dart';
import 'package:roam_pulse/features/native_widget/plan_widget_data.dart';

void main() {
  group('ConnectivityWidgetData', () {
    test('toJson serializes all fields with an ISO8601 timestamp', () {
      final data = ConnectivityWidgetData(
        state: 'connected',
        carrierName: 'SoftBank',
        technology: '5G',
        lastSyncedAt: DateTime.utc(2026, 9, 4, 12, 30),
      );

      expect(data.toJson(), {
        'state': 'connected',
        'carrierName': 'SoftBank',
        'technology': '5G',
        'lastSyncedAt': '2026-09-04T12:30:00.000Z',
      });
    });
  });

  group('PlanWidgetData', () {
    test('toJson serializes all fields', () {
      const data = PlanWidgetData(
        destinationCity: 'Tokyo',
        countryCode: 'JP',
        dataRemainingMb: 4200,
        dataAllowanceMb: 8000,
        daysRemaining: 4,
      );

      expect(data.toJson(), {
        'destinationCity': 'Tokyo',
        'countryCode': 'JP',
        'dataRemainingMb': 4200.0,
        'dataAllowanceMb': 8000.0,
        'daysRemaining': 4,
      });
    });
  });
}
