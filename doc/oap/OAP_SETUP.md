# SkyWalking OAP setup for skywalking-dart

Align OAP with this agent (OTLP **12800**, native gRPC **11800**, service layer **DART**).

## 1. `application.yml` (server-starter)

```yaml
receiver-otel:
  selector: ${SW_OTEL_RECEIVER:default}
  default:
    enabledHandlers: ${SW_OTEL_RECEIVER_ENABLED_HANDLERS:"otlp-traces,otlp-metrics,otlp-logs"}
    enabledOtelMetricsRules: ${SW_OTEL_RECEIVER_ENABLED_OTEL_METRICS_RULES:"...,dart/*"}

receiver-zipkin:
  selector: ${SW_RECEIVER_ZIPKIN:default}

query-zipkin:
  selector: ${SW_QUERY_ZIPKIN:default}
```

`core.gRPCHost` / `core.gRPCPort` must listen on **0.0.0.0:11800** for native/hybrid trace export.

After edits: **rebuild OAP** (`mvn clean package -DskipTests` in `oap-server`) and restart.

## 2. OTLP metric rules

Copy [dart-otlp.yaml](dart-otlp.yaml) to:

`oap-server/server-starter/src/main/resources/otel-rules/dart/dart-otlp.yaml`

Rule id in config is **`dart/dart-otlp`** → enable via `dart/*` in `enabledOtelMetricsRules`.

## 3. `Layer.DART` (required for rules + native registration)

In `oap-server/server-core/.../Layer.java`, add:

```java
    /**
     * Dart / Flutter apps (skywalking-dart OTLP + native gRPC).
     */
    DART(43, true);
```

Rebuild OAP after changing `Layer.java`.

## 4. Verify

```powershell
Invoke-WebRequest http://127.0.0.1:9412/zipkin/api/v2/services -UseBasicParsing

cd path/to/skywalking-dart
$env:OTEL_EXPORTER_OTLP_ENDPOINT = "http://127.0.0.1:12800"
$env:OTEL_SERVICE_NAME = "xt-open-app"
dart run bin/verify_otlp.dart --quick

$env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = "127.0.0.1:11800"
dart run bin/verify_native.dart
```

Inspect: `http://127.0.0.1:17128/inspect/metrics?regex=meter_flutter`

## 5. Agent modes (skywalking-dart ≥ 0.1.4)

| Mode | Trace | Metrics | Log |
|------|-------|---------|-----|
| `otlp` | OTLP 12800 | OTLP 12800 | — |
| `hybrid` | gRPC 11800 | OTLP 12800 | gRPC 11800 |
| `nativeFull` | gRPC 11800 | gRPC 11800 | gRPC 11800 |

Flutter: `--dart-define=SKYWALKING_AGENT_MODE=hybrid` when only 12800 is reachable through a tunnel.

## 6. UI

- **Trace (OTLP)**: Horizon → **OTel & Zipkin Traces**, service = `OTEL_SERVICE_NAME`
- **Trace (native)**: **LAYERS → DART → Traces**
- **Metrics**: **OPERATE → Metrics inspect** → **MAL-OTEL → dart → dart-otlp**

Legacy filename [flutter-otlp.yaml](flutter-otlp.yaml) is deprecated; use **dart-otlp.yaml** only.
