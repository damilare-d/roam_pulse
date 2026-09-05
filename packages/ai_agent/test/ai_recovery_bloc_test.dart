import 'package:ai_agent/ai_agent.dart';
import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAiRecoveryRepository implements AiRecoveryRepository {
  _FakeAiRecoveryRepository(this._result);

  final Result<AiRecommendation> _result;

  @override
  Future<Result<AiRecommendation>> getRecommendation() async => _result;
}

const _aiRec = AiRecommendation(
  summary: 'Everything looks good.',
  steps: ['No action needed.'],
  confidence: 0.95,
  escalate: false,
  source: 'ai',
);

void main() {
  group('AiRecoveryBloc', () {
    test('starts in AiRecoveryInitial', () {
      final bloc = AiRecoveryBloc(_FakeAiRecoveryRepository(const Ok(_aiRec)));
      expect(bloc.state, isA<AiRecoveryInitial>());
    });

    test('emits [loading, loaded] when the request succeeds', () {
      final bloc = AiRecoveryBloc(_FakeAiRecoveryRepository(const Ok(_aiRec)));

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AiRecoveryLoading>(),
          isA<AiRecoveryLoaded>().having(
            (s) => s.recommendation.source,
            'recommendation.source',
            'ai',
          ),
        ]),
      );

      bloc.add(const AiRecommendationRequested());
    });

    test('emits [loading, failed] when the request fails', () {
      final bloc = AiRecoveryBloc(
        _FakeAiRecoveryRepository(const Err(NetworkUnavailableFailure())),
      );

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AiRecoveryLoading>(), isA<AiRecoveryFailed>()]),
      );

      bloc.add(const AiRecommendationRequested());
    });
  });
}
