import 'native_segment_ref.dart';
import 'native_span.dart';
import 'proto_writer.dart';

/// Minimal protobuf encoder for `SegmentCollection` / `SegmentObject` / `SpanObject`.
abstract final class SegmentProtoCodec {
  static List<int> encodeCollection(List<NativeSpanData> spans) {
    final bySegment = <String, List<NativeSpanData>>{};
    for (final span in spans) {
      bySegment.putIfAbsent(span.traceSegmentId, () => []).add(span);
    }
    final writer = ProtoWriter();
    for (final entry in bySegment.entries) {
      final group = entry.value;
      if (group.isEmpty) continue;
      final first = group.first;
      writer.writeMessage(
        1,
        encodeSegment(
          traceId: first.traceId,
          traceSegmentId: first.traceSegmentId,
          service: first.tags['service.name'] ?? 'unknown',
          serviceInstance: first.tags['service.instance'] ?? 'unknown',
          spans: group,
        ),
      );
    }
    return writer.toBytes();
  }

  static List<int> encodeSegment({
    required String traceId,
    required String traceSegmentId,
    required String service,
    required String serviceInstance,
    required List<NativeSpanData> spans,
  }) {
    final writer = ProtoWriter();
    writer.writeString(1, traceId);
    writer.writeString(2, traceSegmentId);
    final ordered = List<NativeSpanData>.from(spans)
      ..sort((a, b) => a.spanId.compareTo(b.spanId));
    for (final span in ordered) {
      writer.writeMessage(3, encodeSpan(span));
    }
    writer.writeString(4, service);
    writer.writeString(5, serviceInstance);
    return writer.toBytes();
  }

  static List<int> encodeSpan(NativeSpanData span) {
    final writer = ProtoWriter();
    writer.writeInt32(1, span.spanId);
    writer.writeInt32(2, span.parentSpanId);
    writer.writeInt64(3, span.startTimeMs);
    writer.writeInt64(4, span.endTimeMs);
    writer.writeString(6, span.operationName);
    if (span.peer.isNotEmpty) {
      writer.writeString(7, span.peer);
    }
    writer.writeInt32(8, span.spanType.wire);
    writer.writeInt32(9, span.spanLayer.wire);
    writer.writeInt32(10, span.componentId);
    writer.writeBool(11, span.isError);
    for (final entry in span.tags.entries) {
      if (entry.key == 'service.name' || entry.key == 'service.instance') {
        continue;
      }
      writer.writeMessage(12, encodeKeyStringValuePair(entry.key, entry.value));
    }
    for (final ref in span.refs) {
      writer.writeMessage(16, encodeRef(ref));
    }
    return writer.toBytes();
  }

  static List<int> encodeRef(NativeSegmentRef ref) {
    final writer = ProtoWriter();
    writer.writeInt32(1, ref.refType.wire);
    writer.writeString(2, ref.traceId);
    writer.writeString(3, ref.parentTraceSegmentId);
    writer.writeInt32(4, ref.parentSpanId);
    writer.writeString(5, ref.parentService);
    writer.writeString(6, ref.parentServiceInstance);
    writer.writeString(7, ref.parentEndpoint);
    writer.writeString(8, ref.networkAddressUsedAtPeer);
    return writer.toBytes();
  }

}
