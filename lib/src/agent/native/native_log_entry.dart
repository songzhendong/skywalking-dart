/// Pending native gRPC log record.
class NativeLogEntry {
  const NativeLogEntry({
    required this.message,
    this.timestampMs,
    this.endpoint = '',
    this.traceId,
    this.traceSegmentId,
    this.spanId,
    this.tags = const {},
    this.bodyType = 'text',
  });

  final String message;
  final int? timestampMs;
  final String endpoint;
  final String? traceId;
  final String? traceSegmentId;
  final int? spanId;
  final Map<String, String> tags;
  final String bodyType;
}
