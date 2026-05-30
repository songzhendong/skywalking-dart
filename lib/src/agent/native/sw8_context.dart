/// Active SkyWalking trace context for cross-process propagation (`sw8` header).
class Sw8Context {
  const Sw8Context({
    required this.sample,
    required this.traceId,
    required this.traceSegmentId,
    required this.spanId,
    required this.service,
    required this.serviceInstance,
    required this.endpoint,
    required this.peer,
  });

  final int sample;
  final String traceId;
  final String traceSegmentId;
  final int spanId;
  final String service;
  final String serviceInstance;
  final String endpoint;
  final String peer;
}
