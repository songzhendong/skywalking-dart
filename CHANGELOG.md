# Changelog

Release notes for GitHub tags: [doc/releases/](doc/releases/).

## 0.2.2

- Move `TopologySimulator` to `test/support/` (smoke / unit tests only).
- Runtime tuning via dart-define / env: `SKYWALKING_FLUSH_INTERVAL_SEC`, `SKYWALKING_MAX_BATCH_SIZE`, `SKYWALKING_MAX_QUEUE_SIZE`, `SKYWALKING_LOG_SAMPLE_RATE` (ERROR logs always kept).
- Archive OTLP-era scripts under `scripts/archive/`.
- Docs: [doc/OPEN_SOURCE.md](doc/OPEN_SOURCE.md), [doc/releases/v0.2.2.md](doc/releases/v0.2.2.md); README examples use generic service names (`my-app`).
- CI: `dart test` + optional OAP Docker smoke (`verify_native.dart --quick`).

## 0.2.1

- Remove deprecated `usesOtlpTraces` / `usesOtlpMetrics` / `usesOtlpLogs` getters (`AgentConfig`, `AgentMode`).
- Example and docs: native gRPC only (no OTLP wording).

## 0.2.0

- **Breaking:** OTLP / hybrid / `dart-otlp` removed; agent is **nativeFull only** (gRPC 11800: Trace + Meter + Log).
- Removed `agent/otlp/`, `bin/verify_otlp.dart`, `doc/oap/dart-otlp.yaml`; docs and example updated for native agent.
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
