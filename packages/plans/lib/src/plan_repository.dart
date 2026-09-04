import 'package:core/core.dart';
import 'package:network/network.dart';

import 'plan_summary.dart';

abstract interface class PlanRepository {
  Future<Result<PlanSummary>> getCurrentPlanSummary();
}

class HttpPlanRepository implements PlanRepository {
  const HttpPlanRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<PlanSummary>> getCurrentPlanSummary() {
    return _client.getJson(
      '/api/v1/plans/current',
      fromJson: PlanSummary.fromJson,
    );
  }
}
