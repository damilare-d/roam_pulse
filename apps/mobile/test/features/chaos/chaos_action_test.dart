import 'package:flutter_test/flutter_test.dart';
import 'package:roam_pulse/features/chaos/chaos_action.dart';
import 'package:roam_pulse/features/chaos/chaos_condition.dart';

void main() {
  group('decideChaosAction', () {
    test('passes through when both conditions are normal', () {
      final action = decideChaosAction(
        network: NetworkCondition.normal,
        api: ApiCondition.normal,
      );
      expect(action, isA<ChaosPassThrough>());
    });

    test('network offline rejects immediately regardless of API condition', () {
      final action = decideChaosAction(
        network: NetworkCondition.offline,
        api: ApiCondition.serverError,
      );
      expect(action, isA<ChaosRejectOffline>());
    });

    test(
      'network timeout rejects as a timeout regardless of API condition',
      () {
        final action = decideChaosAction(
          network: NetworkCondition.timeout,
          api: ApiCondition.emptyResponse,
        );
        expect(action, isA<ChaosRejectTimeout>());
      },
    );

    test('network slow delays even when API condition is normal', () {
      final action = decideChaosAction(
        network: NetworkCondition.slow,
        api: ApiCondition.normal,
      );
      expect(action, isA<ChaosDelay>());
    });

    test(
      'network condition takes priority over API condition — you cannot get a 500 while offline',
      () {
        final action = decideChaosAction(
          network: NetworkCondition.offline,
          api: ApiCondition.normal,
        );
        expect(action, isA<ChaosRejectOffline>());
        expect(action, isNot(isA<ChaosRejectServerError>()));
      },
    );

    test('API server error applies only when network is normal', () {
      final action = decideChaosAction(
        network: NetworkCondition.normal,
        api: ApiCondition.serverError,
      );
      expect(action, isA<ChaosRejectServerError>());
    });

    test('API empty response applies only when network is normal', () {
      final action = decideChaosAction(
        network: NetworkCondition.normal,
        api: ApiCondition.emptyResponse,
      );
      expect(action, isA<ChaosResolveEmpty>());
    });

    test(
      'API delayed applies only when network is normal, with its own duration',
      () {
        final action = decideChaosAction(
          network: NetworkCondition.normal,
          api: ApiCondition.delayed,
        );
        expect(action, isA<ChaosDelay>());
        expect((action as ChaosDelay).duration, const Duration(seconds: 2));
      },
    );

    test(
      'slow network and delayed API use different, deliberately-chosen durations',
      () {
        final slow =
            decideChaosAction(
                  network: NetworkCondition.slow,
                  api: ApiCondition.normal,
                )
                as ChaosDelay;
        final delayed =
            decideChaosAction(
                  network: NetworkCondition.normal,
                  api: ApiCondition.delayed,
                )
                as ChaosDelay;
        expect(slow.duration, isNot(delayed.duration));
      },
    );
  });
}
