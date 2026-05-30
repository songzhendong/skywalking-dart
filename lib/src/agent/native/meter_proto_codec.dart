import 'native_meter_sample.dart';
import 'proto_writer.dart';

/// Minimal protobuf encoder for `MeterDataCollection` / `MeterData`.
abstract final class MeterProtoCodec {
  static List<int> encodeCollection({
    required String service,
    required String serviceInstance,
    required int timestampMs,
    required List<NativeMeterSample> samples,
  }) {
    final writer = ProtoWriter();
    for (final sample in samples) {
      writer.writeMessage(
        1,
        encodeMeterData(
          service: service,
          serviceInstance: serviceInstance,
          timestampMs: timestampMs,
          sample: sample,
        ),
      );
    }
    return writer.toBytes();
  }

  static List<int> encodeMeterData({
    required String service,
    required String serviceInstance,
    required int timestampMs,
    required NativeMeterSample sample,
  }) {
    final writer = ProtoWriter();
    writer.writeMessage(1, encodeSingleValue(sample));
    writer.writeString(3, service);
    writer.writeString(4, serviceInstance);
    writer.writeInt64(5, timestampMs);
    return writer.toBytes();
  }

  static List<int> encodeSingleValue(NativeMeterSample sample) {
    final writer = ProtoWriter();
    writer.writeString(1, sample.name);
    for (final entry in sample.attributes.entries) {
      writer.writeMessage(2, encodeLabel(entry.key, entry.value));
    }
    writer.writeDouble(3, sample.value);
    return writer.toBytes();
  }

  static List<int> encodeLabel(String name, String value) {
    final writer = ProtoWriter();
    writer.writeString(1, name);
    writer.writeString(2, value);
    return writer.toBytes();
  }
}
