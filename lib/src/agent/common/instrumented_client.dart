import 'package:http/http.dart' as http;

import '../../semconv.dart';
import '../common/agent_meter.dart';
import '../native/native_config.dart';
import '../native/segment_exporter.dart';
import '../native/sw8_context.dart';
import '../native/sw8_propagator.dart';
import 'id_generator.dart';

/// [http.Client] with native Exit spans, HTTP metrics, and `sw8` injection.
class InstrumentedClient extends http.BaseClient {
  InstrumentedClient({
    required http.Client inner,
    this.nativeExporter,
    this.nativeConfig,
    this.meter,
    this.injectSw8 = true,
    IdGenerator? idGenerator,
  })  : _inner = inner,
        _ids = idGenerator ?? nativeExporter?.idGenerator;

  final http.Client _inner;
  final SegmentExporter? nativeExporter;
  final NativeAgentConfig? nativeConfig;
  final AgentMeter? meter;
  final bool injectSw8;
  final IdGenerator? _ids;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final traceId = _ids?.traceId() ?? '0';
    final spanId = _ids?.spanId() ?? '0';
    final segmentId = _ids?.segmentId() ?? spanId;
    final start = DateTime.now();
    final path = request.url.path.isEmpty ? '/' : request.url.path;
    final spanName = Semconv.httpSpanName(request.method, path);
    final peer = '${request.url.host}:${request.url.port}';

    if (injectSw8 && nativeConfig != null) {
      Sw8Propagator.inject(
        request,
        Sw8Context(
          sample: 1,
          traceId: traceId,
          traceSegmentId: segmentId,
          spanId: 0,
          service: nativeConfig!.serviceName,
          serviceInstance: nativeConfig!.serviceInstanceId,
          endpoint: spanName,
          peer: peer,
        ),
      );
    }

    try {
      final streamed = await _inner.send(request);
      final bytes = await streamed.stream.toBytes();
      final response = http.Response.bytes(
        bytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: streamed.request,
        isRedirect: streamed.isRedirect,
        persistentConnection: streamed.persistentConnection,
        reasonPhrase: streamed.reasonPhrase,
      );
      final elapsed = DateTime.now().difference(start);
      final end = DateTime.now();
      _recordNative(
        operationName: spanName,
        traceId: traceId,
        segmentId: segmentId,
        peer: peer,
        start: start,
        end: end,
        isError: response.statusCode >= 500,
        request: request,
        statusCode: response.statusCode,
      );
      _recordHttpMetrics(request, response.statusCode, elapsed);
      return http.StreamedResponse(
        Stream.value(bytes),
        response.statusCode,
        headers: response.headers,
        request: response.request,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase,
      );
    } catch (e) {
      final elapsed = DateTime.now().difference(start);
      final end = DateTime.now();
      _recordNative(
        operationName: spanName,
        traceId: traceId,
        segmentId: segmentId,
        peer: peer,
        start: start,
        end: end,
        isError: true,
        request: request,
        statusCode: 0,
        error: e,
      );
      _recordHttpMetrics(request, 0, elapsed, error: true);
      rethrow;
    }
  }

  void _recordNative({
    required String operationName,
    required String traceId,
    required String segmentId,
    required String peer,
    required DateTime start,
    required DateTime end,
    required bool isError,
    required http.BaseRequest request,
    required int statusCode,
    Object? error,
  }) {
    final exporter = nativeExporter;
    if (exporter == null) return;
    final tags = Semconv.httpClientAttributes(
      method: request.method,
      url: request.url,
      statusCode: statusCode,
    );
    if (error != null) {
      tags[Semconv.exceptionType] = error.runtimeType.toString();
      tags[Semconv.exceptionMessage] = error.toString();
    }
    exporter.enqueue(
      exporter.buildHttpExitSpan(
        traceId: traceId,
        traceSegmentId: segmentId,
        operationName: operationName,
        peer: peer,
        start: start,
        end: end,
        isError: isError,
        tags: tags,
      ),
    );
  }

  void _recordHttpMetrics(
    http.BaseRequest request,
    int statusCode,
    Duration elapsed, {
    bool error = false,
  }) {
    final m = meter;
    if (m == null) return;
    final path = request.url.path.isEmpty ? '/' : request.url.path;
    final status = error
        ? 'error'
        : (statusCode >= 500
            ? '5xx'
            : statusCode >= 400
                ? '4xx'
                : 'ok');
    final attrs = <String, String>{
      Semconv.httpRequestMethod: request.method.toUpperCase(),
      Semconv.urlPath: path,
      Semconv.httpResponseStatusCode: statusCode.toString(),
      'http.response.status_class': status,
    };
    m.addCounter(Semconv.metricHttpClientRequests, attributes: attrs);
    m.recordDuration(
      Semconv.metricHttpClientRequestDuration,
      elapsed,
      attributes: attrs,
    );
  }

  @override
  void close() {
    _inner.close();
  }
}
