/// SkyWalking agent reporting mode.
import 'telemetry_channel.dart';

enum AgentMode {
  /// OTLP/HTTP JSON (`POST /v1/traces`, `/v1/metrics` on port 12800).
  otlp,

  /// Native Trace + Log on gRPC 11800; metrics on OTLP 12800 (`sw8` on traces).
  ///
  /// Use when 12800 is reachable (LAN / peanut-shell OTLP) but 11800 is not.
  hybrid,

  /// SkyWalking native Trace + Meter + Log on gRPC 11800 (with `sw8` propagation).
  nativeFull;

  static AgentMode parse(String? raw, {AgentMode fallback = AgentMode.nativeFull}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    switch (raw.trim().toLowerCase().replaceAll('-', '_')) {
      case 'otlp':
      case 'otlp_with_sw8':
      case 'otlpwithsw8':
        return AgentMode.otlp;
      case 'hybrid':
        return AgentMode.hybrid;
      case 'native_full':
      case 'nativefull':
      case 'skywalking':
      case 'full':
      case 'full_native':
      case 'native':
        return AgentMode.nativeFull;
      default:
        return fallback;
    }
  }
}

extension AgentModeX on AgentMode {
  bool get usesOtlpTraces => this == AgentMode.otlp;

  bool get usesNativeTraces =>
      this == AgentMode.nativeFull || this == AgentMode.hybrid;

  TelemetryChannel get defaultMetricsChannel {
    switch (this) {
      case AgentMode.nativeFull:
        return TelemetryChannel.native;
      case AgentMode.hybrid:
      case AgentMode.otlp:
        return TelemetryChannel.otlp;
    }
  }

  TelemetryChannel get defaultLogsChannel {
    switch (this) {
      case AgentMode.nativeFull:
      case AgentMode.hybrid:
        return TelemetryChannel.native;
      case AgentMode.otlp:
        return TelemetryChannel.none;
    }
  }

  bool get injectSw8 =>
      this == AgentMode.nativeFull || this == AgentMode.hybrid;
}
