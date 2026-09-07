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
      // A genuine Claude round-trip routinely exceeds ApiClient's default
      // 10s timeout (sized for fast Postgres-backed endpoints); comfortably
      // longer than ClaudeClient's own 20s server-side timeout
      // (backend/api/internal/service/claude_client.go) so the backend
      // gets a real chance to either succeed or fall back before the
      // client gives up first.
      receiveTimeout: const Duration(seconds: 45),
    );
  }
}
