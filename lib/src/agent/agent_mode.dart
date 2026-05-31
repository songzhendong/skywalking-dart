/// SkyWalking native gRPC agent mode (Trace + Meter + Log @ 11800).
enum AgentMode {
  nativeFull;

  /// Legacy values map to [nativeFull]; only native gRPC is supported.
  static AgentMode parse(String? raw, {AgentMode fallback = AgentMode.nativeFull}) {
    return AgentMode.nativeFull;
  }
}

extension AgentModeX on AgentMode {
  bool get usesOtlpTraces => false;

  bool get usesNativeTraces => true;

  bool get injectSw8 => true;
}
