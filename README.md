# skywalking_dart

<div align="right">

[![English](https://img.shields.io/badge/lang-English-blue?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/lang-简体中文-red?style=flat-square)](doc/USAGE.md)

</div>

[![GitHub](https://img.shields.io/badge/GitHub-songzhendong%2Fskywalking--dart-blue)](https://github.com/songzhendong/skywalking-dart)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

SkyWalking **native gRPC** agent for **Dart & Flutter**: Trace (Segment), Meter, and Log on port **11800**, aligned with the Java agent and Horizon **Layer.DART** dashboards.

| Item | Value |
|------|--------|
| Dart package | `skywalking_dart` |
| Runtime | Dart / Flutter apps |
| Protocol | gRPC **11800** (`Segment`, `MeterReportService`, `LogReportService`) |
| Agent mode | **`nativeFull` only** (OTLP / hybrid removed) |
| SDK | Dart `>=3.0.0` |

## Features

- `SkywalkingAgent` → native tracer / meter / logs / `httpClient()` (sw8 propagation)
- `AgentConfig.fromEnvironment` + `--dart-define` (Flutter-friendly)
- CLI smoke: `bin/verify_native.dart` (topology demo or `--quick`)
- OAP meter rules: [doc/oap/dart-native-meter.yaml](doc/oap/dart-native-meter.yaml)

## Documentation

| Doc | Description |
|-----|-------------|
| [doc/USAGE.md](doc/USAGE.md) | Install, defines, API, troubleshooting (**简体中文**) |
| [doc/OPEN_SOURCE.md](doc/OPEN_SOURCE.md) | Standalone use without xt_open_app backend |
| [doc/oap/OAP_SETUP.md](doc/oap/OAP_SETUP.md) | OAP `Layer.DART`, meter-analyzer, gRPC 11800 |
| [CHANGELOG.md](CHANGELOG.md) | Version history |

## Install

**Git**:

```yaml
dependencies:
  skywalking_dart:
    git:
      url: https://github.com/songzhendong/skywalking-dart.git
      ref: v0.2.2
```

**Path** (monorepo):

```yaml
dependencies:
  skywalking_dart:
    path: packages/skywalking-dart
```

## Quick start (Flutter)

```dart
import 'package:flutter/material.dart';
import 'package:skywalking_dart/skywalking_dart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SkywalkingAgent.initFromEnvironment(
    defaultNativeBackend: '192.168.1.10:11800',
    defaultServiceName: 'my-flutter-app',
    dartDefines: const {
      'SKYWALKING_AGENT_MODE': 'nativeFull',
      'SKYWALKING_METRICS_ENABLED': 'true',
    },
  );

  runApp(const MyApp());
}
```

HTTP with instrumentation:

```dart
final client = SkywalkingAgent.instance.httpClient();
await client.get(Uri.parse('https://api.example.com/health'));
```

Custom span + meter:

```dart
SkywalkingAgent.instance.nativeTracer.recordSpan(
  name: 'checkout',
  duration: const Duration(milliseconds: 120),
);
SkywalkingAgent.instance.meter?.addCounter('orders.created');
```

## `--dart-define` (recommended)

```bash
flutter run \
  --dart-define=SKYWALKING_AGENT_MODE=nativeFull \
  --dart-define=SKYWALKING_METRICS_ENABLED=true \
  --dart-define=SW_AGENT_COLLECTOR_BACKEND_SERVICES=192.168.1.10:11800 \
  --dart-define=APP_VERSION=1.0.0+1
```

| Define | Purpose |
|--------|---------|
| `SW_AGENT_COLLECTOR_BACKEND_SERVICES` | OAP gRPC `host:11800` |
| `SKYWALKING_LAN_HOST` / `DEFAULT_SKYWALKING_LAN_HOST` | Dev LAN IP → `:11800` |
| `SKYWALKING_SERVICE_NAME` / `SW_AGENT_NAME` | Service name in UI |
| `APP_VERSION` | Instance / build version (Browser-style charts) |
| `SKYWALKING_ENABLED=false` | Disable agent |
| `SKYWALKING_METRICS_ENABLED=false` | Trace + logs only |
| `SKYWALKING_FLUSH_INTERVAL_SEC` | Periodic flush (default `5`) |
| `SKYWALKING_MAX_QUEUE_SIZE` | Drop oldest when queue full (default `512`) |
| `SKYWALKING_LOG_SAMPLE_RATE` | Sample non-ERROR logs `0–1` (ERROR always kept) |

Legacy values `otlp`, `hybrid`, `SKYWALKING_OTLP_ENDPOINT` are **ignored** (mapped to `nativeFull`).

## OAP configuration

See [doc/oap/OAP_SETUP.md](doc/oap/OAP_SETUP.md): enable **DART** layer, copy **dart-native-meter** rules, listen on **0.0.0.0:11800**.

## Verify

```powershell
cd path/to/skywalking-dart
$env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = "127.0.0.1:11800"
$env:SKYWALKING_SERVICE_NAME = "my-app"
dart run bin/verify_native.dart --quick
```

## Standalone vs xt_open_app

This package **does not require** the [xt_open_app](https://github.com/songzhendong/xt_open_app) backend. You only need **SkyWalking OAP** on gRPC **11800** with DART layer + meter rules ([OAP_SETUP.md](doc/oap/OAP_SETUP.md)).

[xt_open_app](https://github.com/songzhendong/xt_open_app) is a reference Flutter app (extra `SkywalkingMonitoring` helpers, PC dev settings, LAN scripts). See [doc/USAGE.md §9](doc/USAGE.md#9-与-xt_open_app-集成可选).

## License

Apache License 2.0 — see [LICENSE](LICENSE).
