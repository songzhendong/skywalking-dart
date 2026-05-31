import 'package:skywalking_dart/src/agent/agent_config.dart';
import 'package:skywalking_dart/src/agent/agent_mode.dart';
import 'package:skywalking_dart/src/agent/telemetry_channel.dart';
import 'package:test/test.dart';

void main() {
  test('AgentMode.parse always nativeFull', () {
    expect(AgentMode.parse('otlp'), AgentMode.nativeFull);
    expect(AgentMode.parse('hybrid'), AgentMode.nativeFull);
    expect(AgentMode.parse('nativeFull'), AgentMode.nativeFull);
    expect(AgentMode.parse(null), AgentMode.nativeFull);
  });

  test('nativeFull uses native gRPC for trace metrics and logs', () {
    const mode = AgentMode.nativeFull;
    expect(mode.usesNativeTraces, isTrue);
    expect(mode.usesOtlpTraces, isFalse);
    expect(mode.injectSw8, isTrue);
  });

  test('AgentConfig.fromEnvironment uses native metrics and logs', () {
    final cfg = AgentConfig.fromEnvironment(
      dartDefines: const {
        'SKYWALKING_AGENT_MODE': 'otlp',
        'APP_VERSION': '1.0.0+1',
        'SW_AGENT_INSTANCE_NAME': '1.0.0+1',
      },
    );
    expect(cfg.mode, AgentMode.nativeFull);
    expect(cfg.metricsChannel, TelemetryChannel.native);
    expect(cfg.logsChannel, TelemetryChannel.native);
    expect(cfg.usesOtlpMetrics, isFalse);
    expect(cfg.native.serviceInstanceId, '1.0.0+1');
  });

  test('SKYWALKING_METRICS_ENABLED=false disables meter channel', () {
    final cfg = AgentConfig.fromEnvironment(
      dartDefines: const {'SKYWALKING_METRICS_ENABLED': 'false'},
    );
    expect(cfg.metricsChannel, TelemetryChannel.none);
    expect(cfg.logsChannel, TelemetryChannel.native);
  });
}
