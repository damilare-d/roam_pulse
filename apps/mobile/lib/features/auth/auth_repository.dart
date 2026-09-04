import 'package:core/core.dart';
import 'package:network/network.dart';
import 'package:storage/storage.dart';

import 'auth_session.dart';

/// The auth boundary the brief calls for (docs/PRODUCT_DISCOVERY.md §3):
/// today the only implementation is [HttpAuthRepository] talking to the
/// demo endpoint, but the interface is shaped so a future
/// JwtAuthRepository or OAuthRepository slots in without callers changing
/// — see ADR-010.
abstract interface class AuthRepository {
  Future<Result<AuthSession>> signInDemo();

  Future<bool> hasActiveSession();

  Future<void> signOut();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._client, this._store);

  final ApiClient _client;
  final KeyValueStore _store;

  /// Public so tests can read/seed the same slot without duplicating a
  /// magic string.
  static const sessionTokenKey = 'auth.sessionToken';

  @override
  Future<Result<AuthSession>> signInDemo() async {
    final result = await _client.postJson(
      '/api/v1/auth/demo',
      fromJson: AuthSession.fromJson,
    );
    if (result case Ok(:final value)) {
      await _store.setString(sessionTokenKey, value.sessionToken);
    }
    return result;
  }

  @override
  Future<bool> hasActiveSession() async {
    final token = await _store.getString(sessionTokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> signOut() => _store.remove(sessionTokenKey);
}
