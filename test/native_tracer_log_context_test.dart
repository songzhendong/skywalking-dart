import 'dart:math';

import 'package:skywalking_dart/src/agent/common/id_generator.dart';
import 'package:skywalking_dart/src/agent/native/native_config.dart';
import 'package:skywalking_dart/src/agent/native/native_tracer.dart';
import 'package:skywalking_dart/src/agent/native/segment_exporter.dart';
import 'package:test/test.dart';

import 'support/test_native_clients.dart';

void main() {
  late SegmentExporter exporter;
  late NativeTracer tracer;

  setUp(() {
    final config = NativeAgentConfig(
      serviceName: 'test-app',
      backendAddress: '127.0.0.1:9',
      serviceInstance: 'test-inst',
    );
    exporter = SegmentExporter(
      config,
      client: NoopTraceClient(),
      ids: IdGenerator(random: Random(1)),
    );
    tracer = NativeTracer(exporter);
  });

  test('lastSpanContext reflects most recent recordSpan', () {
    tracer.recordSpan(
      name: 'verify.native.smoke',
      duration: const Duration(milliseconds: 10),
      attributes: {'smoke.run_id': 'run-1'},
    );
    final ctx = tracer.lastSpanContext;
    expect(ctx, isNotNull);
    expect(ctx!.isValid, isTrue);
    expect(ctx.operationName, 'verify.native.smoke');
    expect(ctx.traceId, hasLength(32));
    expect(ctx.traceSegmentId, hasLength(32));
    expect(ctx.spanId, 0);
  });
}
