import 'package:core/core.dart';
import 'package:network/network.dart';

import 'trip_summary.dart';

abstract interface class TripRepository {
  Future<Result<TripSummary>> getCurrentTrip();
}

class HttpTripRepository implements TripRepository {
  const HttpTripRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<TripSummary>> getCurrentTrip() {
    return _client.getJson(
      '/api/v1/trips/current',
      fromJson: TripSummary.fromJson,
    );
  }
}
