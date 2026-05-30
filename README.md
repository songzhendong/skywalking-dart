# skywalking_dart

<div align="right">

[![English](https://img.shields.io/badge/lang-English-blue?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-red?style=flat-square)](doc/USAGE.md)

</div>

[![GitHub](https://img.shields.io/badge/GitHub-songzhendong%2Fskywalking--dart-blue)](https://github.com/songzhendong/skywalking-dart)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

OpenTelemetry **OTLP/HTTP** **skywalking-dart** plugin for **traces** and **metrics**, compatible with [Apache SkyWalking OAP](https://skywalking.apache.org/) (`receiver-otel` on port **12800**).

| Item | Value |
|------|--------|
| Dart package | `skywalking_dart` |
| Runtime | Dart / Flutter apps |
| Protocol | `POST /v1/traces`, `POST /v1/metrics` (HTTP JSON) |
| Version | 0.1.4 |
| SDK | Dart `>=3.0.0` |

## Features

- Standard OTLP over HTTP JSON (OpenTelemetry-aligned env vars)
- `OtlpAgent` → `tracer` / `meter` / `httpClient()`
- HTTP client spans + `http.client.requests` / `http.client.request.duration`
- `OtlpFlutter.init()` reads `--dart-define` (Flutter-friendly)
- CLI smoke test: `bin/verify_otlp.dart`
- Sample OAP MAL rules: [doc/oap/dart-otlp.yaml](doc/oap/dart-otlp.yaml)

## Screenshots (Horizon UI)

Examples use service **`xt-open-app`** and OAP rule **`dart/dart-otlp`**. Setup: [doc/oap/OAP_SETUP.md](doc/oap/OAP_SETUP.md), [doc/USAGE.md](doc/USAGE.md).

<table>
  <tr>
    <td align="center" width="50%">
      <a href="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-metrics-inspect.png">
        <img src="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-metrics-inspect.png" width="420" alt="Metrics inspect"/>
      </a>
    </td>
    <td align="center" width="50%">
      <a href="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-trace-parent-child.png">
        <img src="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-trace-parent-child.png" width="420" alt="Trace parent-child"/>
      </a>
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <a href="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-zipkin-traces-list.png">
        <img src="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-zipkin-traces-list.png" width="420" alt="Trace list"/>
      </a>
    </td>
    <td align="center" width="50%">
      <a href="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-zipkin-trace-detail.png">
        <img src="https://github.com/songzhendong/skywalking-dart/raw/main/doc/images/horizon-zipkin-trace-detail.png" width="420" alt="Span detail"/>
      </a>
    </td>
  </tr>
</table>

## Documentation

| Doc | Description |
|-----|-------------|
| [doc/USAGE.md](doc/USAGE.md) | Full guide in **简体中文** (install, OAP, API, troubleshooting) |
| [doc/oap/OAP_SETUP.md](doc/oap/OAP_SETUP.md) | OAP `application.yml`, `Layer.DART`, rebuild |
| [doc/oap/dart-otlp.yaml](doc/oap/dart-otlp.yaml) | OAP `dart-otlp` MAL rules sample |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## Install

**Git** (apps and SkyWalking-related repos):

```yaml
dependencies:
  skywalking_dart:
    git:
      url: https://github.com/songzhendong/skywalking-dart.git
      ref: main
```

**Path** (local):

```yaml
dependencies:
  skywalking_dart:
    path: ../skywalking-dart
```

Then resolve dependencies (`dart pub get`; Flutter apps may use `flutter pub get`).

## Quick start (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:skywalking_dart/skywalking_dart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  OtlpFlutter.init(
    defaultServiceName: 'my-flutter-app',
    defaultEndpoint: 'http://127.0.0.1:12800',
  );

  runApp(const MyApp());
}
```

HTTP with auto instrumentation:

```dart
final client = OtlpAgent.instance.httpClient();
await client.get(Uri.parse('https://api.example.com/health'));
```

Custom span + metric:

```dart
await OtlpAgent.instance.tracer.withSpan('checkout', (_) async {
  // business logic
});
OtlpAgent.instance.meter.addCounter('orders.created');
```

## `--dart-define` (recommended)

```bash
flutter run \
  --dart-define=OTEL_SERVICE_NAME=my-flutter-app \
  --dart-define=OTEL_EXPORTER_OTLP_ENDPOINT=http://10.0.2.2:12800
```

| Define | Purpose |
|--------|---------|
| `OTEL_EXPORTER_OTLP_ENDPOINT` | OTLP base URL (no `/v1/traces` suffix) |
| `OTEL_SERVICE_NAME` | Service name in UI |
| `SKYWALKING_OTLP_ENDPOINT` | Alias for endpoint |
| `SKYWALKING_ENABLED=false` | Disable agent |
| `SKYWALKING_METRICS_ENABLED=false` | Traces only |

## OAP configuration

```yaml
receiver-otel:
  default:
    enabledHandlers: otlp-traces,otlp-metrics,otlp-logs
query-zipkin:
  selector: default   # Zipkin UI for traces
```

Follow [doc/oap/OAP_SETUP.md](doc/oap/OAP_SETUP.md): copy [doc/oap/dart-otlp.yaml](doc/oap/dart-otlp.yaml), add `Layer.DART`, enable `dart/*` and OTLP handlers, enable `query-zipkin`. Rebuild and restart OAP. Traces: **OTel & Zipkin Traces** or **LAYERS → DART** (native/hybrid).

## Network pitfall (API vs OTLP)

| Traffic | Example | Port |
|---------|---------|------|
| Business API | `http://your-domain` | 8082 |
| OTLP | `https://your-domain` or `http://host:12800` | 12800 |

Do **not** send `/v1/traces` to the business HTTP port.

## Verify

```powershell
cd path/to/skywalking-dart
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "flutter-otlp-verify"
dart run bin/verify_otlp.dart
```

## License

Apache License 2.0 — see [LICENSE](LICENSE).
