/// Trace / metrics / logs transport channel (OTLP HTTP vs SkyWalking native gRPC).
enum TelemetryChannel {
  otlp,
  native,
  none;

  static TelemetryChannel parse(
    String? raw, {
    TelemetryChannel fallback = TelemetryChannel.none,
  }) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    switch (raw.trim().toLowerCase().replaceAll('-', '_')) {
      case 'otlp':
      case 'http':
        return TelemetryChannel.otlp;
      case 'native':
      case 'grpc':
      case 'skywalking':
        return TelemetryChannel.native;
      case 'none':
      case 'off':
      case 'false':
      case '0':
        return TelemetryChannel.none;
      default:
        return fallback;
    }
  }
}
