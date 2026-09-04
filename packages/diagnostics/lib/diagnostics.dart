/// Deterministic connectivity diagnostic engine — client-side domain
/// model, repository, and bloc for `POST /api/v1/diagnostics`. The
/// engine itself runs on the backend (ADR-009); this package consumes its
/// structured output.
library;

export 'src/diagnosis.dart';
export 'src/diagnostic_check.dart';
export 'src/diagnostics_bloc.dart';
export 'src/diagnostics_repository.dart';
