import 'native_log_entry.dart';
import 'native_log_trace_context.dart';

/// Resolves trace context and endpoint for a native log (Java agent parity).
NativeLogEntry resolveNativeLogEntry({
  required String message,
  String endpoint = '',
  Map<String, String> tags = const {},
  String? traceId,
  String? traceSegmentId,
  int? spanId,
  String bodyType = 'text',
  NativeLogTraceContext? activeContext,
}) {
  var resolvedTraceId = traceId;
  var resolvedSegmentId = traceSegmentId;
  var resolvedSpanId = spanId;
  var resolvedEndpoint = endpoint;

  if (activeContext != null && activeContext.isValid) {
    resolvedTraceId ??= activeContext.traceId;
    resolvedSegmentId ??= activeContext.traceSegmentId;
    resolvedSpanId ??= activeContext.spanId;
    if (resolvedEndpoint.isEmpty) {
      resolvedEndpoint = activeContext.operationName;
    }
  }

  return NativeLogEntry(
    message: message,
    endpoint: resolvedEndpoint,
    tags: tags,
    traceId: resolvedTraceId,
    traceSegmentId: resolvedSegmentId,
    spanId: resolvedSpanId,
    bodyType: bodyType,
  );
}
