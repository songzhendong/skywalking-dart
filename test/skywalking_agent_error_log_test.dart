import 'dart:math';

import 'package:skywalking_dart/src/agent/common/id_generator.dart';
import 'package:skywalking_dart/src/agent/native/native_agent.dart';
import 'package:skywalking_dart/src/agent/native/native_config.dart';
import 'package:skywalking_dart/src/semconv.dart';
import 'package:skywalking_dart/skywalking_dart.dart';
import 'package:test/test.dart';

import 'support/test_native_clients.dart';

void main() {
  const nativeConfig = NativeAgentConfig(
    serviceName: 'test-app',
    backendAddress: '127.0.0.1:9',
    serviceInstance: 'test-inst',
  );

  late CapturingLogClient logClient;

  setUp(() {
    logClient = CapturingLogClient();
    SkywalkingAgent.init(
      AgentConfig(
        mode: AgentMode.nativeFull,
        native: nativeConfig,
        metricsChannel: TelemetryChannel.native,
        logsChannel: TelemetryChannel.native,
      ),
      periodicNativeFlush: false,
      registerNativeService: false,
      nativeTraceClient: NoopTraceClient(),
      nativeLogClient: logClient,
      nativeManagementClient: NoopManagementClient(),
      nativeIdGenerator: IdGenerator(random: Random(3)),
    );
  });

  tearDown(() async {
    if (SkywalkingAgent.isInitialized) {
      await SkywalkingAgent.instance.shutdown();
    }
    if (NativeAgent.isInitialized) {
      await NativeAgent.instance.shutdown();
    }
  });

  test('reportErrorLog enqueues ERROR log linked to active span', () async {
    final agent = SkywalkingAgent.instance;
    agent.nativeTracer.recordSpan(
      name: 'exception',
      duration: Duration.zero,
      isError: true,
    );
    final traceId = agent.nativeTracer.lastSpanContext!.traceId;

    agent.reportErrorLog(
      StateError('verify_native_smoke_error|run-2'),
      context: 'verify.native.smoke',
    );
    await agent.flush();

    expect(logClient.entries, hasLength(1));
    final log = logClient.entries.single;
    expect(log.tags['level'], 'ERROR');
    expect(log.tags[Semconv.exceptionType], 'StateError');
    expect(log.tags['exception.message'], contains('verify_native_smoke_error'));
    expect(log.traceId, traceId);
  });
}
