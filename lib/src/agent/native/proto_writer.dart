import 'dart:convert';
import 'dart:typed_data';

/// Minimal protobuf wire encoder shared by native management + segment codecs.
class ProtoWriter {
  final List<int> _buf = [];

  List<int> toBytes() => List<int>.from(_buf);

  void writeString(int field, String value) {
    final utf8Bytes = utf8.encode(value);
    _writeTag(field, 2);
    _writeVarint(utf8Bytes.length);
    _buf.addAll(utf8Bytes);
  }

  void writeInt32(int field, int value) {
    _writeTag(field, 0);
    _writeVarint(value);
  }

  void writeInt64(int field, int value) {
    _writeTag(field, 0);
    _writeVarint(value);
  }

  void writeBool(int field, bool value) {
    _writeTag(field, 0);
    _writeVarint(value ? 1 : 0);
  }

  void writeDouble(int field, double value) {
    _writeTag(field, 1);
    final data = ByteData(8)..setFloat64(0, value, Endian.little);
    _buf.addAll(data.buffer.asUint8List());
  }

  void writeMessage(int field, List<int> nested) {
    _writeTag(field, 2);
    _writeVarint(nested.length);
    _buf.addAll(nested);
  }

  void _writeTag(int field, int wire) {
    _writeVarint((field << 3) | wire);
  }

  void _writeVarint(int value) {
    var v = value.toUnsigned(64);
    while (v > 0x7F) {
      _buf.add((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _buf.add(v & 0x7F);
  }
}

List<int> encodeKeyStringValuePair(String key, String value) {
  final writer = ProtoWriter();
  writer.writeString(1, key);
  writer.writeString(2, value);
  return writer.toBytes();
}
