import 'package:core/core.dart';
import 'package:network/network.dart';

import 'usage_summary.dart';

abstract interface class UsageRepository {
  Future<Result<UsageSummary>> getUsageSummary();
}

class HttpUsageRepository implements UsageRepository {
  const HttpUsageRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<UsageSummary>> getUsageSummary() {
    return _client.getJson('/api/v1/usage', fromJson: UsageSummary.fromJson);
  }
}
