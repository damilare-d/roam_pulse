/// The local persistence seam RoamPulse's repositories cache through.
/// Deliberately minimal in Phase 3 — TTL, staleness, and
/// stale-while-revalidate behaviour are Phase 6's job (offline-first
/// caching, see docs/PRODUCT_DISCOVERY.md); this is just "get/set a
/// string by key" so that logic has something concrete to build on.
abstract interface class KeyValueStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  Future<void> clear();
}
