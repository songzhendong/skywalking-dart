import 'native_log_entry.dart';
import 'proto_writer.dart';

/// Minimal protobuf encoder for `LogData`.
abstract final class LogProtoCodec {
  static List<int> encode({
    required String service,
    required String serviceInstance,
    required String layer,
    required NativeLogEntry entry,
  }) {
    final writer = ProtoWriter();
    final ts = entry.timestampMs ?? DateTime.now().millisecondsSinceEpoch;
    writer.writeInt64(1, ts);
    writer.writeString(2, service);
    writer.writeString(3, serviceInstance);
    if (entry.endpoint.isNotEmpty) {
      writer.writeString(4, entry.endpoint);
    }
    writer.writeMessage(5, encodeBody(entry.bodyType, entry.message));
    final trace = encodeTraceContext(entry);
    if (trace.isNotEmpty) {
      writer.writeMessage(6, trace);
    }
    if (entry.tags.isNotEmpty) {
      writer.writeMessage(7, encodeTags(entry.tags));
    }
    writer.writeString(8, layer);
    return writer.toBytes();
  }

  static List<int> encodeBody(String type, String text) {
    final writer = ProtoWriter();
    writer.writeString(1, type);
    final textLog = ProtoWriter()..writeString(1, text);
    writer.writeMessage(2, textLog.toBytes());
    return writer.toBytes();
  }

  static List<int> encodeTraceContext(NativeLogEntry entry) {
    final writer = ProtoWriter();
    var wrote = false;
    final traceId = entry.traceId?.trim();
    if (traceId != null && traceId.isNotEmpty) {
      writer.writeString(1, traceId);
      wrote = true;
    }
    final segmentId = entry.traceSegmentId?.trim();
    if (segmentId != null && segmentId.isNotEmpty) {
      writer.writeString(2, segmentId);
      wrote = true;
    }
    final spanId = entry.spanId;
    if (spanId != null) {
      writer.writeInt32(3, spanId);
      wrote = true;
    }
    return wrote ? writer.toBytes() : const [];
  }

  static List<int> encodeTags(Map<String, String> tags) {
    final writer = ProtoWriter();
    for (final entry in tags.entries) {
      writer.writeMessage(1, encodeKeyStringValuePair(entry.key, entry.value));
    }
    return writer.toBytes();
  }
}
