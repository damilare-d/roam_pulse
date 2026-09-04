/// A value alongside when it was last successfully fetched, and whether
/// it's past its TTL. Repositories that cache (see packages/storage's
/// `Cache<T>`) return this instead of a bare value specifically so the UI
/// can never show cached data as if it were fresh — see
/// docs/PRODUCT_DISCOVERY.md principle 2 ("never lie about freshness").
class Cached<T> {
  const Cached({
    required this.value,
    required this.syncedAt,
    required this.isStale,
  });

  final T value;
  final DateTime syncedAt;
  final bool isStale;
}
