import 'package:core/core.dart';
import 'package:network/network.dart';

import 'ai_recommendation.dart';

abstract interface class AiRecoveryRepository {
  Future<Result<AiRecommendation>> getRecommendation();
}

class HttpAiRecoveryRepository implements AiRecoveryRepository {
  const HttpAiRecoveryRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<AiRecommendation>> getRecommendation() {
    return _client.postJson(
      '/api/v1/diagnostics/recommend',
      fromJson: AiRecommendation.fromJson,
    );
  }
}
