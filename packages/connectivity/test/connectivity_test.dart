import 'package:connectivity/connectivity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectivityStatus.fromJson', () {
    test('parses a full response including throughput', () {
      final status = ConnectivityStatus.fromJson({
        'state': 'connected',
        'network': {'carrierName': 'SoftBank', 'technology': '5G'},
        'signalStrength': 'strong',
        'latencyMs': 42,
        'downloadMbps': 87.0,
        'uploadMbps': 21.0,
        'lastEventAt': '2026-09-01T09:23:08Z',
      });

      expect(status.state, ConnectivityState.connected);
      expect(status.network.carrierName, 'SoftBank');
      expect(status.network.technology, '5G');
      expect(status.signalStrength, 'strong');
      expect(status.latencyMs, 42);
      expect(status.downloadMbps, 87.0);
      expect(status.uploadMbps, 21.0);
      expect(status.lastEventAt, DateTime.parse('2026-09-01T09:23:08Z'));
    });

    test('parses a response with no latency/throughput (e.g. offline)', () {
      final status = ConnectivityStatus.fromJson({
        'state': 'offline',
        'network': {'carrierName': 'Movistar', 'technology': '4G'},
        'signalStrength': 'none',
        'latencyMs': null,
        'lastEventAt': '2026-05-05T00:00:00Z',
      });

      expect(status.state, ConnectivityState.offline);
      expect(status.latencyMs, isNull);
      expect(status.downloadMbps, isNull);
      expect(status.uploadMbps, isNull);
    });

    test('toJson round-trips through fromJson', () {
      final original = ConnectivityStatus.fromJson({
        'state': 'degraded',
        'network': {'carrierName': 'Orange', 'technology': '4G'},
        'signalStrength': 'weak',
        'latencyMs': 320,
        'downloadMbps': 3.2,
        'uploadMbps': 0.8,
        'lastEventAt': '2026-05-05T00:00:00Z',
      });

      final roundTripped = ConnectivityStatus.fromJson(original.toJson());

      expect(roundTripped.state, original.state);
      expect(roundTripped.downloadMbps, original.downloadMbps);
      expect(roundTripped.uploadMbps, original.uploadMbps);
      expect(roundTripped.lastEventAt, original.lastEventAt);
    });
  });

  group('ConnectivityEvent.fromJson', () {
    test('parses a transition with a reason', () {
      final event = ConnectivityEvent.fromJson({
        'occurredAt': '2026-05-05T00:00:00Z',
        'fromState': 'connected',
        'toState': 'degraded',
        'reason': 'high latency and packet loss',
      });

      expect(event.fromState, ConnectivityState.connected);
      expect(event.toState, ConnectivityState.degraded);
      expect(event.reason, 'high latency and packet loss');
    });

    test('parses a transition with no reason', () {
      final event = ConnectivityEvent.fromJson({
        'occurredAt': '2026-05-05T00:00:00Z',
        'fromState': 'connecting',
        'toState': 'connected',
        'reason': null,
      });

      expect(event.reason, isNull);
    });
  });
}
