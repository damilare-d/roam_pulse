import 'package:core/core.dart';
import 'package:network/network.dart';

import 'traveller_profile.dart';

abstract interface class ProfileRepository {
  Future<Result<TravellerProfile>> getProfile();
}

class HttpProfileRepository implements ProfileRepository {
  const HttpProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<TravellerProfile>> getProfile() {
    return _client.getJson(
      '/api/v1/profile',
      fromJson: TravellerProfile.fromJson,
    );
  }
}
