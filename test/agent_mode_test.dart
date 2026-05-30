import 'package:skywalking_dart/skywalking_dart.dart';
import 'package:test/test.dart';

void main() {
  test('AgentMode.parse', () {
    expect(AgentMode.parse('otlp'), AgentMode.otlp);
    expect(AgentMode.parse('nativeFull'), AgentMode.nativeFull);
    expect(AgentMode.parse('skywalking'), AgentMode.nativeFull);
    expect(AgentMode.parse('hybrid'), AgentMode.hybrid);
    expect(AgentMode.parse('native'), AgentMode.nativeFull);
    expect(AgentMode.parse('otlp_with_sw8'), AgentMode.otlp);
    expect(AgentMode.parse(null), AgentMode.nativeFull);
  });

  test('nativeFull uses native gRPC for trace metrics and logs', () {
    const mode = AgentMode.nativeFull;
    expect(mode.defaultMetricsChannel, TelemetryChannel.native);
    expect(mode.defaultLogsChannel, TelemetryChannel.native);
    expect(mode.usesNativeTraces, isTrue);
    expect(mode.injectSw8, isTrue);
  });

  test('hybrid uses native trace/log and OTLP metrics', () {
    const mode = AgentMode.hybrid;
    expect(mode.defaultMetricsChannel, TelemetryChannel.otlp);
    expect(mode.defaultLogsChannel, TelemetryChannel.native);
    expect(mode.usesNativeTraces, isTrue);
    expect(mode.usesOtlpTraces, isFalse);
    expect(mode.injectSw8, isTrue);
  });

  test('otlp uses OTLP for trace and metrics', () {
    const mode = AgentMode.otlp;
    expect(mode.defaultMetricsChannel, TelemetryChannel.otlp);
    expect(mode.defaultLogsChannel, TelemetryChannel.none);
    expect(mode.usesOtlpTraces, isTrue);
    expect(mode.injectSw8, isFalse);
  });

  test('AgentConfig uses static version as instance id (browser-style)', () {
    final cfg = AgentConfig.fromEnvironment(
      dartDefines: const {
        'OTEL_SERVICE_NAME': 'my-app',
        'APP_VERSION': '1.0.0+1',
      },
      defaultServiceName: 'fallback',
    );
    expect(cfg.otlp.serviceInstanceId, cfg.native.serviceInstanceId);
    expect(cfg.otlp.serviceInstanceId, '1.0.0+1');
    expect(cfg.otlp.serviceVersion, '1.0.0+1');
    expect(cfg.native.serviceVersion, '1.0.0+1');
  });

  test('AgentConfig mode selects channels', () {
    final nativeCfg = AgentConfig.fromEnvironment(
      dartDefines: const {'SKYWALKING_AGENT_MODE': 'nativeFull'},
      defaultServiceName: 'my-app',
    );
    expect(nativeCfg.metricsChannel, TelemetryChannel.native);
    expect(nativeCfg.logsChannel, TelemetryChannel.native);

    final hybridCfg = AgentConfig.fromEnvironment(
      dartDefines: const {'SKYWALKING_AGENT_MODE': 'hybrid'},
      defaultServiceName: 'my-app',
    );
    expect(hybridCfg.metricsChannel, TelemetryChannel.otlp);
    expect(hybridCfg.logsChannel, TelemetryChannel.native);

    final otlpCfg = AgentConfig.fromEnvironment(
      dartDefines: const {'SKYWALKING_AGENT_MODE': 'otlp'},
      defaultServiceName: 'my-app',
    );
    expect(otlpCfg.metricsChannel, TelemetryChannel.otlp);
    expect(otlpCfg.logsChannel, TelemetryChannel.none);
  });

  test('AgentConfig falls back to unknown instance without version', () {
    final cfg = AgentConfig.fromEnvironment(
      dartDefines: const {'OTEL_SERVICE_NAME': 'my-app'},
      defaultServiceName: 'fallback',
    );
    expect(cfg.otlp.serviceInstanceId, 'unknown');
    expect(cfg.native.serviceInstanceId, 'unknown');
  });
}
