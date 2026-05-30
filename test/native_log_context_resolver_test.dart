import 'package:skywalking_dart/src/agent/native/native_log_context_resolver.dart';
import 'package:skywalking_dart/src/agent/native/native_log_trace_context.dart';
import 'package:test/test.dart';

void main() {
  const active = NativeLogTraceContext(
    traceId: 'trace-parent-001',
    traceSegmentId: 'segment-parent-001',
    spanId: 3,
    operationName: 'verify.native.smoke',
  );

  test('fills missing trace fields from active span context', () {
    final entry = resolveNativeLogEntry(
      message: 'hello',
      activeContext: active,
    );
    expect(entry.traceId, active.traceId);
    expect(entry.traceSegmentId, active.traceSegmentId);
    expect(entry.spanId, active.spanId);
    expect(entry.endpoint, active.operationName);
  });

  test('explicit trace ids override active context', () {
    final entry = resolveNativeLogEntry(
      message: 'hello',
      traceId: 'explicit-trace',
      traceSegmentId: 'explicit-seg',
      spanId: 9,
      endpoint: 'custom.endpoint',
      activeContext: active,
    );
    expect(entry.traceId, 'explicit-trace');
    expect(entry.traceSegmentId, 'explicit-seg');
    expect(entry.spanId, 9);
    expect(entry.endpoint, 'custom.endpoint');
  });

  test('keeps empty trace when no active context', () {
    final entry = resolveNativeLogEntry(message: 'orphan');
    expect(entry.traceId, isNull);
    expect(entry.traceSegmentId, isNull);
    expect(entry.spanId, isNull);
  });
}
