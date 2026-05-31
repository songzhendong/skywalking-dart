import 'dart:convert';

import 'package:skywalking_dart/src/agent/native/log_proto_codec.dart';
import 'package:skywalking_dart/src/agent/native/native_log_entry.dart';
import 'package:test/test.dart';

void main() {
  test('encode includes trace id and exception tags in payload', () {
    const entry = NativeLogEntry(
      message: 'verify_native_smoke_log|run-1|native_full',
      endpoint: 'verify.native.smoke',
      traceId: 'trace-abc123',
      traceSegmentId: 'segment-def456',
      spanId: 0,
      tags: {
        'level': 'ERROR',
        'exception.type': 'StateError',
        'exception.message': 'bad state',
      },
    );
    final bytes = LogProtoCodec.encode(
      service: 'my-app',
      serviceInstance: 'test-instance',
      layer: 'DART',
      entry: entry,
    );
    final text = utf8.decode(bytes, allowMalformed: true);
    expect(text, contains('trace-abc123'));
    expect(text, contains('segment-def456'));
    expect(text, contains('verify_native_smoke_log'));
    expect(text, contains('exception.type'));
    expect(text, contains('StateError'));
  });

  test('encode omits trace context when trace id absent', () {
    const entry = NativeLogEntry(message: 'no-trace-log');
    expect(LogProtoCodec.encodeTraceContext(entry), isEmpty);
    final bytes = LogProtoCodec.encode(
      service: 'my-app',
      serviceInstance: 'test-instance',
      layer: 'DART',
      entry: entry,
    );
    expect(bytes, isNotEmpty);
    expect(utf8.decode(bytes, allowMalformed: true), contains('no-trace-log'));
  });
}
