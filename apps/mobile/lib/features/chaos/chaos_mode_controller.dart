import 'package:flutter/foundation.dart';

import 'chaos_condition.dart';

/// Holds the developer console's current dials. A plain [ChangeNotifier]
/// (registered via `ChangeNotifierProvider`, not `RepositoryProvider` —
/// provider's own debug check flags a Listenable handed to the latter)
/// rather than a bloc — this is dev-only UI state with no async
/// lifecycle, request handling, or failure path of its own; see §21 and
/// ADR-002's "don't bloc everything" note (SplashPage is the earlier
/// example of the same call).
class ChaosModeController extends ChangeNotifier {
  NetworkCondition _network = NetworkCondition.normal;
  ApiCondition _api = ApiCondition.normal;

  NetworkCondition get network => _network;
  ApiCondition get api => _api;

  void setNetwork(NetworkCondition value) {
    _network = value;
    notifyListeners();
  }

  void setApi(ApiCondition value) {
    _api = value;
    notifyListeners();
  }

  void reset() {
    _network = NetworkCondition.normal;
    _api = ApiCondition.normal;
    notifyListeners();
  }
}
