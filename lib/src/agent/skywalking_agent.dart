import 'package:http/http.dart' as http;



import 'agent_config.dart';

import 'agent_mode.dart';

import 'common/agent_meter.dart';

import 'native/native_agent.dart';

import 'native/native_tracer.dart';

import 'otlp/otlp_agent.dart';

import 'common/instrumented_client.dart';

import 'otlp/otlp_span.dart';

import 'otlp/otlp_tracer.dart';

import '../semconv.dart';



/// Unified SkyWalking agent (OTLP + optional native Segment/Meter/Log).

class SkywalkingAgent {

  SkywalkingAgent._(

    this.config,

    this._otlp,

    this._native,

  );



  static SkywalkingAgent? _instance;



  final AgentConfig config;

  final OtlpAgent? _otlp;

  final NativeAgent? _native;



  AgentMode get mode => config.mode;



  static SkywalkingAgent init(

    AgentConfig config, {

    http.Client? httpClient,

  }) {

    if (_instance != null) return _instance!;



    OtlpAgent? otlp;

    NativeAgent? native;



    if (config.usesOtlpTraces || config.usesOtlpMetrics) {

      otlp = OtlpAgent.init(config.otlp, httpClient: httpClient);

    }

    if (config.usesNativeTraces ||

        config.usesNativeMetrics ||

        config.usesNativeLogs) {

      native = NativeAgent.init(

        config.native,

        periodicFlush: true,

        tracesEnabled: config.usesNativeTraces,

        metricsEnabled: config.usesNativeMetrics,

        logsEnabled: config.usesNativeLogs,

      );

    }



    _instance = SkywalkingAgent._(config, otlp, native);

    return _instance!;

  }



  static SkywalkingAgent initFromEnvironment({

    Map<String, String> dartDefines = const {},

    AgentMode defaultMode = AgentMode.nativeFull,

    String defaultOtlpEndpoint = 'http://127.0.0.1:12800',

    String defaultNativeBackend = '127.0.0.1:11800',

    String defaultServiceName = 'unknown_service',

    http.Client? httpClient,

  }) =>

      init(

        AgentConfig.fromEnvironment(

          dartDefines: dartDefines,

          defaultMode: defaultMode,

          defaultOtlpEndpoint: defaultOtlpEndpoint,

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



  OtlpAgent? get otlp => _otlp;



  NativeAgent? get native => _native;



  OtlpTracer get otlpTracer {

    final o = _otlp;

    if (o == null) {

      throw StateError('OTLP traces are disabled for mode $mode');

    }

    return o.tracer;

  }



  NativeTracer get nativeTracer {

    final n = _native;

    if (n == null) {

      throw StateError('Native traces are disabled for mode $mode');

    }

    return n.tracer;

  }



  AgentMeter? get meter => _native?.meterIfEnabled ?? _otlp?.meterIfEnabled;



  bool get logsEnabled => config.usesNativeLogs || config.usesOtlpLogs;



  void reportLog({
    required String message,
    String endpoint = '',
    Map<String, String> tags = const {},
    String? traceId,
    String? traceSegmentId,
    int? spanId,
    String bodyType = 'text',
  }) {
    final native = _native;
    if (config.usesNativeLogs && native != null) {
      native.reportLog(
        message: message,
        endpoint: endpoint,
        tags: tags,
        traceId: traceId,
        traceSegmentId: traceSegmentId,
        spanId: spanId,
        bodyType: bodyType,
      );
      return;
    }
    // OTLP logs export is not implemented yet.
  }

  /// Native log with trace context (aligned with Java LogReportService + toolkit).
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



  /// Prefer native tracer when enabled, otherwise OTLP when traces are on.

  void recordBizSpan({

    required String name,

    Duration duration = Duration.zero,

    Map<String, String> attributes = const {},

    bool isError = false,

    bool preferNative = false,

  }) {

    if (preferNative && _native != null) {

      _native!.tracer.recordSpan(

        name: name,

        duration: duration,

        attributes: attributes,

        isError: isError,

      );

      return;

    }

    final otlpTraces = _otlp?.traceExporterIfEnabled;

    if (otlpTraces != null && !preferNative) {

      otlpTraces.enqueue(

        OtlpSpanData(

          name: name,

          traceId: otlpTraces.idGenerator.traceId(),

          spanId: otlpTraces.idGenerator.spanId(),

          startTimeUnixNano:

              DateTime.now().subtract(duration).microsecondsSinceEpoch * 1000,

          endTimeUnixNano: DateTime.now().microsecondsSinceEpoch * 1000,

          kind: OtlpSpanKind.internal,

          statusCode: isError ? OtlpStatusCode.error : OtlpStatusCode.ok,

          attributes: attributes,

        ),

      );

      return;

    }

    if (_native != null) {

      _native!.tracer.recordSpan(

        name: name,

        duration: duration,

        attributes: attributes,

        isError: isError,

      );

    }

  }



  http.Client httpClient({http.Client? inner}) {

    final client = inner ?? http.Client();

    return InstrumentedClient(

      inner: client,

      otlpExporter: _otlp?.traceExporterIfEnabled,

      nativeExporter: _native?.segmentExporter,

      nativeConfig: _native?.config,

      meter: meter,

      injectSw8: config.mode.injectSw8,

    );

  }



  Future<void> flush() async {

    await _otlp?.flush();

    await _native?.flush();

  }



  Future<void> shutdown() async {

    await _otlp?.shutdown();

    await _native?.shutdown();

    _instance = null;

  }

}


