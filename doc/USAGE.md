# skywalking_dart 使用指南

SkyWalking **原生 gRPC 11800** Dart/Flutter Agent（**仅 `nativeFull`**：Trace + Meter + Log）。OTLP / hybrid / `dart-otlp` 已移除。

## 1. 安装

```yaml
dependencies:
  skywalking_dart:
    path: ../tools/skywalking-dart   # 或 git 依赖
```

```bash
dart pub get   # Flutter: flutter pub get
```

## 2. OAP

见 [oap/OAP_SETUP.md](oap/OAP_SETUP.md)：

- `core.gRPCHost: 0.0.0.0`，`core.gRPCPort: 11800`
- `meter-analyzer-config` 启用 `dart-native-meter`、`dart-native-meter-instance`
- `Layer.DART` 已编入 OAP

## 3. Flutter 初始化

```dart
import 'package:skywalking_dart/skywalking_dart.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SkywalkingAgent.initFromEnvironment(
    defaultNativeBackend: '127.0.0.1:11800',
    defaultServiceName: 'xt-open-app',
    dartDefines: const {
      'SKYWALKING_AGENT_MODE': 'nativeFull',
      'SKYWALKING_METRICS_ENABLED': 'true',
    },
  );
  runApp(const MyApp());
}
```

真机调试（电脑局域网 IP）：

```bash
flutter run \
  --dart-define=SKYWALKING_LAN_HOST=192.168.1.10 \
  --dart-define=SW_AGENT_COLLECTOR_BACKEND_SERVICES=192.168.1.10:11800 \
  --dart-define=SKYWALKING_AGENT_MODE=nativeFull \
  --dart-define=APP_VERSION=1.0.0+1
```

## 4. 环境变量 / dart-define

| 键 | 说明 |
|----|------|
| `SW_AGENT_COLLECTOR_BACKEND_SERVICES` | `host:11800` |
| `SKYWALKING_AGENT_MODE` | 任意值均解析为 `nativeFull` |
| `SKYWALKING_METRICS_ENABLED` | `false` 时仅 Trace+Log |
| `SKYWALKING_LOGS_ENABLED` | 默认 `true` |
| `SKYWALKING_SERVICE_NAME` | 服务名 |
| `APP_VERSION` | 实例/构建版本（Horizon 构建版本图） |
| `SKYWALKING_ENABLED` | `false` 关闭 Agent |

## 5. API 摘要

| 类型 | 用法 |
|------|------|
| 初始化 | `SkywalkingAgent.init` / `initFromEnvironment` |
| HTTP | `SkywalkingAgent.instance.httpClient()` |
| Trace | `nativeTracer.recordSpan` / `withSpan` |
| Meter | `meter?.addCounter` / `recordDuration` |
| Log | `reportLog` / `reportErrorLog` |
| 刷新 | `await agent.flush()`；退出前 `shutdown()` |

## 6. 冒烟

```powershell
$env:SW_AGENT_COLLECTOR_BACKEND_SERVICES = "127.0.0.1:11800"
dart run bin/verify_native.dart
dart run bin/verify_native.dart --quick
```

## 7. Horizon

- Trace：**LAYERS → DART → Traces**
- Metrics：**LAYERS → Dart → Service**（`meter_flutter_*`）
- Logs：**LAYERS → DART → Logs**

## 8. 排错

| 现象 | 检查 |
|------|------|
| 无 Trace | OAP 11800 可达；真机勿用 `127.0.0.1:11800` |
| 无 Meter | `SKYWALKING_METRICS_ENABLED=true`；meter 规则已加载 |
| 无构建版本 | 注入非空 `APP_VERSION` |
| `Call SkywalkingAgent.init()` | `main` 中先 `init` |

## 9. 与 xt_open_app 集成

业务封装：`lib/monitoring/skywalking_monitoring.dart`。局域网一键运行：`tools/run-flutter-lan.ps1`。端到端说明：`docs/skywalking_e2e.md`。
