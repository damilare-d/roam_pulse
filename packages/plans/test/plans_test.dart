import 'package:flutter_test/flutter_test.dart';
import 'package:plans/plans.dart';

void main() {
  group('TravellerProfile.fromJson', () {
    test('parses id, displayName, homeCountry', () {
      final profile = TravellerProfile.fromJson({
        'id': 't-1',
        'displayName': 'Alex Morgan',
        'homeCountry': 'United Kingdom',
      });

      expect(profile.id, 't-1');
      expect(profile.displayName, 'Alex Morgan');
      expect(profile.homeCountry, 'United Kingdom');
    });
  });

  group('Destination.fromJson', () {
    test('parses countryCode, city, timezone', () {
      final destination = Destination.fromJson({
        'id': 'd-1',
        'countryCode': 'JP',
        'city': 'Tokyo',
        'timezone': 'Asia/Tokyo',
      });

      expect(destination.countryCode, 'JP');
      expect(destination.city, 'Tokyo');
      expect(destination.timezone, 'Asia/Tokyo');
    });
  });

  group('TravelPlan.fromJson', () {
    test('parses dates and status', () {
      final plan = TravelPlan.fromJson({
        'id': 'p-1',
        'destinationId': 'd-1',
        'startsAt': '2026-09-01T10:23:08Z',
        'expiresAt': '2026-09-07T10:23:08Z',
        'dataAllowanceMb': 8000,
        'status': 'active',
      });

      expect(plan.dataAllowanceMb, 8000);
      expect(plan.status, PlanStatus.active);
      expect(plan.expiresAt, DateTime.parse('2026-09-07T10:23:08Z'));
    });
  });

  group('PlanSummary.fromJson', () {
    test('parses the nested plan plus computed remaining/days fields', () {
      final summary = PlanSummary.fromJson({
        'plan': {
          'id': 'p-1',
          'destinationId': 'd-1',
          'startsAt': '2026-09-01T10:23:08Z',
          'expiresAt': '2026-09-07T10:23:08Z',
          'dataAllowanceMb': 8000,
          'status': 'active',
        },
        'dataAllowanceMb': 8000,
        'dataUsedMb': 1200,
        'dataRemainingMb': 6800,
        'daysRemaining': 3,
      });

      expect(summary.plan.id, 'p-1');
      expect(summary.dataRemainingMb, 6800);
      expect(summary.daysRemaining, 3);
    });
  });

  group('UsageSummary.fromJson', () {
    test('parses total and per-category breakdown', () {
      final summary = UsageSummary.fromJson({
        'planId': 'p-1',
        'totalBytesUsed': 1258291200,
        'byCategory': {'maps': 220200960, 'video': 503316480},
      });

      expect(summary.totalBytesUsed, 1258291200);
      expect(summary.byCategory['maps'], 220200960);
      expect(summary.byCategory['video'], 503316480);
    });

    test('defaults to an empty map when byCategory is absent', () {
      final summary = UsageSummary.fromJson({
        'planId': 'p-1',
        'totalBytesUsed': 0,
      });

      expect(summary.byCategory, isEmpty);
    });
  });

  group('TripSummary.fromJson', () {
    test('parses traveller, destination, network, and plan together', () {
      final trip = TripSummary.fromJson({
        'traveller': {
          'id': 't-1',
          'displayName': 'Alex Morgan',
          'homeCountry': 'United Kingdom',
        },
        'destination': {
          'id': 'd-1',
          'countryCode': 'JP',
          'city': 'Tokyo',
          'timezone': 'Asia/Tokyo',
        },
        'network': {'carrierName': 'SoftBank', 'technology': '5G'},
        'plan': {
          'id': 'p-1',
          'destinationId': 'd-1',
          'startsAt': '2026-09-01T10:23:08Z',
          'expiresAt': '2026-09-07T10:23:08Z',
          'dataAllowanceMb': 8000,
          'status': 'active',
        },
      });

      expect(trip.traveller.displayName, 'Alex Morgan');
      expect(trip.destination.city, 'Tokyo');
      expect(trip.network.carrierName, 'SoftBank');
      expect(trip.plan.status, PlanStatus.active);
    });
  });
}
