/// Claude connectivity recovery agent — client-side domain model,
/// repository, and bloc for `POST /api/v1/diagnostics/recommend`. Claude
/// itself is only ever called from the backend (ADR-008); this package
/// consumes its structured, validated output.
library;

export 'src/ai_recommendation.dart';
export 'src/ai_recovery_bloc.dart';
export 'src/ai_recovery_repository.dart';
