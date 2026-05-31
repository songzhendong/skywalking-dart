import 'package:http/http.dart' as http;

import 'agent_config.dart';
import 'agent_mode.dart';
import 'common/agent_meter.dart';
import 'common/id_generator.dart';
import 'common/instrumented_client.dart';
import 'native/grpc_log_client.dart';
import 'native/grpc_management_client.dart';
import 'native/grpc_trace_client.dart';
import 'native/native_agent.dart';
import 'native/native_tracer.dart';
import '../semconv.dart';

/// SkyWalking native agent (Trace + Meter + Log on gRPC 11800).
class SkywalkingAgent {
  SkywalkingAgent._(this.config, this._native);

  static SkywalkingAgent? _instance;

  final AgentConfig config;
  final NativeAgent _native;

  AgentMode get mode => config.mode;

  static SkywalkingAgent init(
    AgentConfig config, {
    http.Client? httpClient,
    bool periodicNativeFlush = true,
    bool registerNativeService = true,
    GrpcTraceClient? nativeTraceClient,
    GrpcLogClient? nativeLogClient,
    GrpcManagementClient? nativeManagementClient,
    IdGenerator? nativeIdGenerator,
  }) {
    if (_instance != null) return _instance!;

    final native = NativeAgent.init(
      config.native,
      periodicFlush: periodicNativeFlush,
      tracesEnabled: config.usesNativeTraces,
      metricsEnabled: config.usesNativeMetrics,
      logsEnabled: config.usesNativeLogs,
      registerService: registerNativeService,
      traceClient: nativeTraceClient,
      logClient: nativeLogClient,
      managementClient: nativeManagementClient,
      idGenerator: nativeIdGenerator,
    );

    _instance = SkywalkingAgent._(config, native);
    return _instance!;
  }

  static SkywalkingAgent initFromEnvironment({
    Map<String, String> dartDefines = const {},
    AgentMode defaultMode = AgentMode.nativeFull,
    String defaultNativeBackend = '127.0.0.1:11800',
    String defaultServiceName = 'unknown_service',
    http.Client? httpClient,
  }) =>
      init(
        AgentConfig.fromEnvironment(
          dartDefines: dartDefines,
          defaultMode: defaultMode,
          defaultNativeBackend: defaultNativeBackend,
          defaultServiceName: defaultServiceName,
        ),
        httpClient: httpClient,
      );

  static SkywalkingAgent get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Call SkywalkingAgent.init() before using the agent.');
    }
    return i;
  }

  static bool get isInitialized => _instance != null;

  NativeAgent get native => _native;

  NativeTracer get nativeTracer => _native.tracer;

  AgentMeter? get meter => _native.meterIfEnabled;

  bool get logsEnabled => config.usesNativeLogs;

  void reportLog({
    required String message,
    String endpoint = '',
    Map<String, String> tags = const {},
    String? traceId,
    String? traceSegmentId,
    int? spanId,
    String bodyType = 'text',
  }) {
    if (!config.usesNativeLogs) return;
    _native.reportLog(
      message: message,
      endpoint: endpoint,
      tags: tags,
      traceId: traceId,
      traceSegmentId: traceSegmentId,
      spanId: spanId,
      bodyType: bodyType,
    );
  }

  void reportErrorLog(
    Object error, {
    String context = 'app',
    StackTrace? stack,
    String endpoint = '',
  }) {
    final stackText = stack?.toString();
    final tags = <String, String>{
      'level': 'ERROR',
      'logger': context,
      'exception.context': context,
      Semconv.exceptionType: error.runtimeType.toString(),
      Semconv.exceptionMessage: error.toString(),
      if (stackText != null)
        'exception.stacktrace': stackText.substring(
          0,
          stackText.length.clamp(0, 4096),
        ),
    };
    reportLog(
      message: error.toString(),
      endpoint: endpoint.isEmpty ? context : endpoint,
      tags: tags,
    );
  }

  void recordBizSpan({
    required String name,
    Duration duration = Duration.zero,
    Map<String, String> attributes = const {},
    bool isError = false,
    bool preferNative = false,
  }) {
    _native.tracer.recordSpan(
      name: name,
      duration: duration,
      attributes: attributes,
      isError: isError,
    );
  }

  http.Client httpClient({http.Client? inner}) {
    final client = inner ?? http.Client();
    return InstrumentedClient(
      inner: client,
      nativeExporter: _native.segmentExporter,
      nativeConfig: _native.config,
      meter: meter,
      injectSw8: config.mode.injectSw8,
      idGenerator: _native.segmentExporter?.idGenerator,
    );
  }

  Future<void> flush() async {
    await _native.flush();
  }

  Future<void> shutdown() async {
    await _native.shutdown();
    _instance = null;
  }
}
