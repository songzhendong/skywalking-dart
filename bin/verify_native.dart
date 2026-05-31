// ignore_for_file: avoid_print
/// Smoke test: export native Segment to OAP gRPC (11800).
///
/// Default: multi-service topology demo (app → gateway → backend → redis/mysql).
/// `--quick`: single local span only.
import 'dart:io';

import 'package:skywalking_dart/skywalking_dart.dart';
import 'package:skywalking_dart/src/agent/native/topology_simulator.dart';

Future<void> main(List<String> args) async {
  final quick = args.contains('--quick');
  stdout.writeln('[verify_native] starting...');
  final backend = Platform.environment['SW_AGENT_COLLECTOR_BACKEND_SERVICES'] ??
      Platform.environment['SKYWALKING_NATIVE_BACKEND'] ??
      '127.0.0.1:11800';
  final service =
      Platform.environment['SW_AGENT_NAME'] ?? 'xt-open-app-verify-native';
  final traceCount = int.tryParse(
        Platform.environment['VERIFY_NATIVE_TRACE_COUNT'] ?? '',
      ) ??
      8;
  stdout.writeln('[verify_native] backend=$backend primaryService=$service');
  stdout.writeln(
    '[verify_native] mode=${quick ? 'quick (1 span)' : 'topology ($traceCount traces, 5 services)'}',
  );

  final agent = SkywalkingAgent.init(
    AgentConfig(
      mode: AgentMode.nativeFull,
      native: NativeAgentConfig(
        serviceName: service,
        backendAddress: backend,
        tracesEnabled: true,
      ),
      metricsChannel: TelemetryChannel.none,
      logsChannel: TelemetryChannel.none,
    ),
  );

  final native = agent.native;
  if (native == null) {
    stderr.writeln('FAIL: native agent not initialized');
    exitCode = 1;
    return;
  }

  final exporter = native.segmentExporter;
  if (quick) {
    agent.nativeTracer.recordSpan(
      name: 'verify.native.bootstrap',
      duration: const Duration(milliseconds: 12),
      attributes: {'verify': 'native'},
    );
  } else {
    final spans = TopologySimulator.buildBurst(
      ids: exporter.idGenerator,
      traceCount: traceCount,
      appService: service,
      gatewayService:
          Platform.environment['VERIFY_GATEWAY_SERVICE'] ?? 'xt-gateway',
      backendService:
          Platform.environment['VERIFY_BACKEND_SERVICE'] ?? 'xt-backend',
      cacheService:
          Platform.environment['VERIFY_CACHE_SERVICE'] ?? 'xt-redis',
      databasePeer:
          Platform.environment['VERIFY_DB_SERVICE'] ?? 'mysql',
    );
    exporter.enqueueAll(spans);
    stdout.writeln(
      '[verify_native] enqueued ${spans.length} spans '
      '(${traceCount} traces × 5 services)',
    );
  }

  stdout.writeln('[verify_native] flushing segment via gRPC (timeout 15s)...');
  final ok = await exporter.flush().timeout(
    const Duration(seconds: 15),
    onTimeout: () {
      stderr.writeln(
        'FAIL: gRPC flush timed out. Is OAP up on $backend (native agent port)?',
      );
      return false;
    },
  );
  if (!ok) {
    stderr.writeln(
      'FAIL: native segment export rejected or unreachable at $backend',
    );
    stderr.writeln('Check: OAP started, gRPC 11800 open (native agent port).');
    exitCode = 1;
    await agent.shutdown().timeout(const Duration(seconds: 3), onTimeout: () {});
    return;
  }
  stdout.writeln('OK: native segment export finished -> $backend');
  if (!quick) {
    stdout.writeln(
      'Horizon: Services Dashboard, Last 15m, refresh; expect edges '
      '$service → xt-gateway → xt-backend → xt-redis/mysql',
    );
  }
  await agent.shutdown().timeout(const Duration(seconds: 3), onTimeout: () {});
}
