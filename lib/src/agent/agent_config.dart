import 'agent_mode.dart';
import 'native/native_config.dart';
import 'telemetry_channel.dart';

/// Native-only SkyWalking agent configuration.
class AgentConfig {
  const AgentConfig({
    required this.mode,
    required this.native,
    required this.metricsChannel,
    required this.logsChannel,
  });

  final AgentMode mode;
  final NativeAgentConfig native;
  final TelemetryChannel metricsChannel;
  final TelemetryChannel logsChannel;

  bool get usesNativeTraces => true;

  bool get usesNativeMetrics => metricsChannel == TelemetryChannel.native;

  bool get usesNativeLogs => logsChannel == TelemetryChannel.native;

  factory AgentConfig.fromEnvironment({
    Map<String, String> dartDefines = const {},
    AgentMode defaultMode = AgentMode.nativeFull,
    String defaultNativeBackend = '127.0.0.1:11800',
    String defaultServiceName = 'unknown_service',
    bool defaultMetricsEnabled = true,
  }) {
    final mode = AgentMode.parse(
      _pick(dartDefines, const [
        'SKYWALKING_AGENT_MODE',
        'SW_AGENT_PROTOCOL',
      ]),
      fallback: defaultMode,
    );
    final serviceName = _pick(dartDefines, const [
          'OTEL_SERVICE_NAME',
          'SKYWALKING_SERVICE_NAME',
          'SW_AGENT_NAME',
          'SERVICE_NAME',
        ]) ??
        defaultServiceName;

    final metricsGloballyEnabled = _resolveBool(
      dartDefines,
      'SKYWALKING_METRICS_ENABLED',
      defaultMetricsEnabled,
    );
    final logsGloballyEnabled = _resolveBool(
      dartDefines,
      'SKYWALKING_LOGS_ENABLED',
      true,
    );
    final metricsChannel =
        metricsGloballyEnabled ? TelemetryChannel.native : TelemetryChannel.none;
    final logsChannel =
        logsGloballyEnabled ? TelemetryChannel.native : TelemetryChannel.none;

    final native = NativeAgentConfig.fromEnvironment(
      dartDefines: dartDefines,
      defaultBackend: defaultNativeBackend,
      defaultServiceName: serviceName,
      tracesEnabled: true,
    );

    return AgentConfig(
      mode: mode,
      native: native,
      metricsChannel: metricsChannel,
      logsChannel: logsChannel,
    );
  }

  static bool _resolveBool(
    Map<String, String> dartDefines,
    String key,
    bool fallback,
  ) {
    final picked = _pick(dartDefines, [key]);
    if (picked != null) {
      return _parseBool(picked, fallback);
    }
    final compiled = _define(key);
    if (compiled != null) {
      return _parseBool(compiled, fallback);
    }
    return fallback;
  }

  static bool _parseBool(String raw, bool fallback) {
    switch (raw.trim().toLowerCase()) {
      case 'true':
      case '1':
      case 'yes':
      case 'on':
        return true;
      case 'false':
      case '0':
      case 'no':
      case 'off':
        return false;
      default:
        return fallback;
    }
  }

  static String? _pick(Map<String, String> defines, List<String> keys) {
    for (final key in keys) {
      final v = defines[key]?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  static String? _define(String key) {
    final v = String.fromEnvironment(key);
    return v.trim().isEmpty ? null : v.trim();
  }
}
