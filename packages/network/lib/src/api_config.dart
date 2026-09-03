/// Connection settings for [ApiClient] — see docs/ARCHITECTURE.md section
/// 10. Kept deliberately small: base URL plus the two timeouts the brief
/// calls out explicitly (request/connection timeout).
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 10),
    this.receiveTimeout = const Duration(seconds: 10),
    this.enableLogging = false,
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Verbose request/response logging — Phase 3 keeps this opt-in and off
  /// by default; the app enables it only in development builds.
  final bool enableLogging;
}
