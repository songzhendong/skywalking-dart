# Changelog

## Unreleased

- fix: `LogReportService.collect` now consumes the server `Commands` response stream (same client-streaming issue as meter).
- fix: `MeterReportService.collectBatch` now consumes the server `Commands` response stream so OAP processes native meter batches (grpc-dart client-streaming semantics).

## 0.1.4

- README: use absolute GitHub raw image URLs so screenshots render on pub.dev.

## 0.1.3

- README: remove skywalking_flutter mirror note.

## 0.1.0

- Docs: Horizon Metrics inspect and parent-child trace screenshots (`doc/images/`).
- Initial release: OpenTelemetry OTLP/HTTP skywalking-dart agent (pure Dart library) for traces and metrics.
- Package name `skywalking_dart`; repository https://github.com/songzhendong/skywalking-dart
- Compatible with Apache SkyWalking OAP (`receiver-otel` on port 12800).
- `OtlpAgent`, `OtlpFlutter`, `InstrumentedClient`, and `bin/verify_otlp.dart`.
- Sample OAP MAL rules: `doc/oap/dart-otlp.yaml` (see `doc/oap/OAP_SETUP.md`)
