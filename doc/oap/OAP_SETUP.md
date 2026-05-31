# SkyWalking OAP setup for skywalking-dart (nativeFull only)

Align OAP with the Flutter agent: **native gRPC 11800** (Trace + Meter + Log), service layer **DART**.

## OAP version & storage (important)

| Use case | OAP version | Storage |
|----------|-------------|---------|
| **GitHub CI smoke** | `apache/skywalking-oap-server:10.1.0` | Default embedded (see workflow) |
| **Local quick try** | 10.1.x standalone Docker | Default |
| **Production / 10.2+** | 10.2.0+ | **BanyanDB or Elasticsearch** — [H2 removed in 10.2](https://skywalking.apache.org/events/remove-jdbc-as-storage/) |

Do **not** set `SW_STORAGE=h2` on OAP **10.2.0+**; the process may never listen on **11800**.

## 1. `application.yml` (server-starter)

```yaml
receiver-zipkin:
  selector: ${SW_RECEIVER_ZIPKIN:default}

query-zipkin:
  selector: ${SW_QUERY_ZIPKIN:default}
```

`core.gRPCHost` / `core.gRPCPort` must listen on **0.0.0.0:11800**.

Zipkin (9412) is optional for auxiliary trace search; **Horizon Dart dashboards use native Meter**, not OTLP.

After edits: **rebuild OAP** if `Layer.java` changed, then restart.

## 2. Native meter rules (required)

Copy to `oap-server/server-starter/src/main/resources/meter-analyzer-config/`:

| File | ES prefix |
|------|-----------|
| [dart-native-meter.yaml](dart-native-meter.yaml) | `meter_flutter_*` |
| [dart-native-meter-instance.yaml](dart-native-meter-instance.yaml) | `meter_flutter_instance_*` |

`agent-analyzer.default.meterAnalyzerActiveFiles`:

`...,dart-native-meter,dart-native-meter-instance`

Restart OAP after changes.

## 3. `Layer.DART`

In `oap-server/server-core/.../Layer.java`:

```java
    DART(43, true);
```

## 4. Verify

```powershell
$env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = "127.0.0.1:11800"
$env:SKYWALKING_SERVICE_NAME = "my-app"
dart run bin/verify_native.dart --quick
```

Optional reference app ([xt_open_app](https://github.com/songzhendong/xt_open_app)):

```powershell
.\scripts\skywalking\run-verify-native-full.ps1
```

Inspect: `http://127.0.0.1:17128/inspect/metrics?regex=meter_flutter`

## 5. Horizon UI

- **Trace**: **LAYERS → DART → Traces**
- **Metrics**: **LAYERS → Dart → Service** / **Build versions**
- **Logs**: **LAYERS → DART → Logs**

Inject `APP_VERSION` (or `SW_AGENT_INSTANCE_NAME`) for build-version charts.
