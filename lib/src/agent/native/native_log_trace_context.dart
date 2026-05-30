/// Trace context for correlating native logs with the last enqueued segment span.
class NativeLogTraceContext {
  const NativeLogTraceContext({
    required this.traceId,
    required this.traceSegmentId,
    required this.spanId,
    this.operationName = '',
  });

  final String traceId;
  final String traceSegmentId;
  final int spanId;
  final String operationName;

  bool get isValid =>
      traceId.isNotEmpty && traceSegmentId.isNotEmpty && spanId >= 0;
}
