/// Shared metrics API for SkyWalking native gRPC Meter (11800).
abstract interface class AgentMeter {
  void addCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
    String unit = '1',
  });

  void recordHistogram(
    String name,
    double value, {
    Map<String, String> attributes = const {},
    String unit = '1',
  });

  void recordDuration(
    String name,
    Duration duration, {
    Map<String, String> attributes = const {},
  });
}
