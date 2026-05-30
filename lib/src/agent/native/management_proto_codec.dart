import 'proto_writer.dart';

/// Encodes `skywalking.v3.InstancePingPkg` and `InstanceProperties`.
abstract final class ManagementProtoCodec {
  static List<int> encodeInstancePingPkg({
    required String service,
    required String serviceInstance,
    required String layer,
  }) {
    final writer = ProtoWriter();
    writer.writeString(1, service);
    writer.writeString(2, serviceInstance);
    writer.writeString(3, layer);
    return writer.toBytes();
  }

  static List<int> encodeInstanceProperties({
    required String service,
    required String serviceInstance,
    required String layer,
    Map<String, String> properties = const {},
  }) {
    final writer = ProtoWriter();
    writer.writeString(1, service);
    writer.writeString(2, serviceInstance);
    for (final entry in properties.entries) {
      writer.writeMessage(
        3,
        encodeKeyStringValuePair(entry.key, entry.value),
      );
    }
    writer.writeString(4, layer);
    return writer.toBytes();
  }
}
