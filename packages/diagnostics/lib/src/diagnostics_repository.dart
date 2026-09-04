import 'package:core/core.dart';
import 'package:network/network.dart';

import 'diagnosis.dart';

abstract interface class DiagnosticsRepository {
  Future<Result<Diagnosis>> runDiagnostics();
}

class HttpDiagnosticsRepository implements DiagnosticsRepository {
  const HttpDiagnosticsRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<Diagnosis>> runDiagnostics() {
    return _client.postJson(
      '/api/v1/diagnostics',
      fromJson: Diagnosis.fromJson,
    );
  }
}
