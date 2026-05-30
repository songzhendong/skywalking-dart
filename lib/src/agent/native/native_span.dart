import 'native_segment_ref.dart';

/// Native SkyWalking span before segment export.
class NativeSpanData {
  NativeSpanData({
    required this.traceId,
    required this.traceSegmentId,
    required this.spanId,
    required this.parentSpanId,
    required this.operationName,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.spanType,
    required this.spanLayer,
    required this.componentId,
    required this.isError,
    this.peer = '',
    this.tags = const {},
    this.refs = const [],
  });
  final String traceId;
  final String traceSegmentId;
  final int spanId;
  final int parentSpanId;
  final String operationName;
  final int startTimeMs;
  final int endTimeMs;
  final NativeSpanType spanType;
  final NativeSpanLayer spanLayer;
  final int componentId;
  final bool isError;
  final String peer;
  final Map<String, String> tags;
  final List<NativeSegmentRef> refs;
}

enum NativeSpanType {
  entry(0),
  exit(1),
  local(2);

  const NativeSpanType(this.wire);
  final int wire;
}

enum NativeSpanLayer {
  unknown(0),
  http(3);

  const NativeSpanLayer(this.wire);
  final int wire;
}
