/// SkyWalking native gRPC agent mode (Trace + Meter + Log @ 11800).
enum AgentMode {
  nativeFull;

  /// Ignores [raw] / [fallback]; only [nativeFull] is supported (gRPC 11800).
  static AgentMode parse(String? raw, {AgentMode fallback = AgentMode.nativeFull}) {
    return AgentMode.nativeFull;
  }
}

extension AgentModeX on AgentMode {
  bool get usesNativeTraces => true;

  bool get injectSw8 => true;
}
