/// Shared metrics API for OTLP and SkyWalking native gRPC exporters.
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
