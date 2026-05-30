/// Pending native gRPC meter sample (always `MeterSingleValue`).
class NativeMeterSample {
  NativeMeterSample({
    required this.name,
    required this.value,
    this.attributes = const {},
  });

  final String name;
  final double value;
  final Map<String, String> attributes;
}
