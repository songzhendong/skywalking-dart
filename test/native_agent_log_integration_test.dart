import 'dart:convert';
import 'dart:math';

import 'package:skywalking_dart/src/agent/common/id_generator.dart';
import 'package:skywalking_dart/src/agent/native/native_agent.dart';
import 'package:skywalking_dart/src/agent/native/native_config.dart';
import 'package:test/test.dart';

import 'support/test_native_clients.dart';

void main() {
  const config = NativeAgentConfig(
    serviceName: 'test-app',
    backendAddress: '127.0.0.1:9',
    serviceInstance: 'test-inst',
  );

  late CapturingLogClient logClient;

  setUp(() {
    logClient = CapturingLogClient();
    NativeAgent.init(
      config,
      periodicFlush: false,
      tracesEnabled: true,
      logsEnabled: true,
      registerService: false,
      traceClient: NoopTraceClient(),
      logClient: logClient,
      managementClient: NoopManagementClient(),
      idGenerator: IdGenerator(random: Random(2)),
    );
  });

  tearDown(() async {
    if (NativeAgent.isInitialized) {
      await NativeAgent.instance.shutdown();
    }
  });

  test('reportLog auto-attaches last span trace context', () async {
    final agent = NativeAgent.instance;
    agent.tracer.recordSpan(
      name: 'verify.native.smoke',
      duration: const Duration(milliseconds: 5),
    );
    final ctx = agent.tracer.lastSpanContext!;

    agent.reportLog(message: 'verify_native_smoke_log|run-1|native_full');
    await agent.flush();

    expect(logClient.entries, hasLength(1));
    final log = logClient.entries.single;
    expect(log.traceId, ctx.traceId);
    expect(log.traceSegmentId, ctx.traceSegmentId);
    expect(log.spanId, ctx.spanId);
    expect(log.endpoint, ctx.operationName);
    expect(
      utf8.decode(logClient.payloads.single, allowMalformed: true),
      contains(ctx.traceId),
    );
  });

}

