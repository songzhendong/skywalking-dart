import 'native_span.dart';
import 'segment_exporter.dart';

import 'native_log_trace_context.dart';

/// Native SkyWalking tracer (segment-based).
class NativeTracer {
  NativeTracer(this._exporter);

  final SegmentExporter _exporter;
  NativeLogTraceContext? _lastSpanContext;

  /// Last enqueued span — used to attach trace context to native logs (Java agent style).
  NativeLogTraceContext? get lastSpanContext => _lastSpanContext;

  void recordSpan({
    required String name,
    Duration duration = Duration.zero,
    Map<String, String> attributes = const {},
    bool isError = false,
    String? traceId,
    String? traceSegmentId,
  }) {
    final span = _exporter.buildLocalSpan(
      operationName: name,
      duration: duration,
      isError: isError,
      tags: attributes,
      traceId: traceId,
      traceSegmentId: traceSegmentId,
    );
    _remember(span);
    _exporter.enqueue(span);
  }

  void _remember(NativeSpanData span) {
    _lastSpanContext = NativeLogTraceContext(
      traceId: span.traceId,
      traceSegmentId: span.traceSegmentId,
      spanId: span.spanId,
      operationName: span.operationName,
    );
  }

  Future<T> withSpan<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
  }) async {
    final start = DateTime.now();
    try {
      final result = await action();
      final elapsed = DateTime.now().difference(start);
      recordSpan(
        name: name,
        duration: elapsed,
        attributes: attributes,
        isError: false,
      );
      return result;
    } catch (e) {
      final elapsed = DateTime.now().difference(start);
      recordSpan(
        name: name,
        duration: elapsed,
        attributes: {
          ...attributes,
          'exception.type': e.runtimeType.toString(),
          'exception.message': e.toString(),
        },
        isError: true,
      );
      rethrow;
    }
  }
}
