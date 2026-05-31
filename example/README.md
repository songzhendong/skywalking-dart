# skywalking_dart example (nativeFull)

Flutter 示例：通过 **gRPC 11800** 上报 Trace + Meter。

> **Note:** GitHub CI does not build this app (`dart pub get --no-example`). Run locally with Flutter SDK.

## 前提

- OAP 已监听 `0.0.0.0:11800`
- 已按 [../doc/oap/OAP_SETUP.md](../doc/oap/OAP_SETUP.md) 配置 DART layer 与 meter 规则

## 运行

```bash
cd example
flutter run \
  --dart-define=SW_AGENT_COLLECTOR_BACKEND_SERVICES=127.0.0.1:11800 \
  --dart-define=SKYWALKING_AGENT_MODE=nativeFull
```

Android 模拟器访问本机 OAP：

```bash
flutter run --dart-define=SW_AGENT_COLLECTOR_BACKEND_SERVICES=10.0.2.2:11800
```

点击 **Send sample**，在 Horizon **LAYERS → DART** 查看 Service **`flutter-native-demo`**。
