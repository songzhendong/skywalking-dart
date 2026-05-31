# 开源使用说明

## 最小依赖

1. SkyWalking OAP（gRPC **11800** 对客户端可达）
2. 按 [oap/OAP_SETUP.md](oap/OAP_SETUP.md) 启用 **Layer.DART** 与 `dart-native-meter` 规则
3. 在应用中 `SkywalkingAgent.initFromEnvironment(...)`

**不需要** xt_open_app 后端、MySQL 业务库或 PC 运营端。

## 推荐 `pubspec` 引用

```yaml
dependencies:
  skywalking_dart:
    git:
      url: https://github.com/songzhendong/skywalking-dart.git
      ref: v0.2.2   # 或固定 commit SHA
```

## 验证

```bash
export SW_AGENT_COLLECTOR_BACKEND_SERVICES=127.0.0.1:11800
dart run bin/verify_native.dart --quick
```

## 与 Java 服务拓扑

HTTP 出口使用 `SkywalkingAgent.instance.httpClient()` 会注入 **sw8**。下游需 SkyWalking Java Agent 或兼容头解析，才能在 OAP 看到跨服务边。

## 问题反馈

[GitHub Issues](https://github.com/songzhendong/skywalking-dart/issues) — 请附 OAP 版本、dart-define、`verify_native` 输出与 Horizon 截图说明。
