import 'dart:async';

import '../common/id_generator.dart';
import 'grpc_trace_client.dart';
import 'native_config.dart';
import 'native_span.dart';

/// Batches and exports native SkyWalking segments via gRPC.
class SegmentExporter {
  SegmentExporter(this.config, {GrpcTraceClient? client, IdGenerator? ids})
      : _client = client ??
            GrpcTraceClient(
              host: config.backendHostPort.$1,
              port: config.backendHostPort.$2,
            ),
        _ids = ids ?? IdGenerator();

  final NativeAgentConfig config;
  final GrpcTraceClient _client;
  final IdGenerator _ids;

  final List<NativeSpanData> _queue = [];
  Timer? _timer;
  bool _closed = false;

  IdGenerator get idGenerator => _ids;

  void start() {
    _timer ??= Timer.periodic(config.flushInterval, (_) => flush());
  }

  void enqueue(NativeSpanData span) {
    if (_closed) return;
    _queue.add(span);
    if (_queue.length >= config.maxBatchSize) {
      unawaited(flush());
    }
  }

  void enqueueAll(Iterable<NativeSpanData> spans) {
    for (final span in spans) {
      enqueue(span);
    }
  }

  Future<bool> flush() async {
    if (_closed || _queue.isEmpty) {
      // ignore: avoid_print
      print('[skywalking_dart] flush skipped (queue empty or closed)');
      return true;
    }
    // ignore: avoid_print
    print('[skywalking_dart] flush ${ _queue.length} segment(s)');
    final batch = List<NativeSpanData>.from(_queue);
    _queue.clear();
    return _client.collectInSync(batch);
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await flush();
    await _client.close();
  }

  NativeSpanData buildHttpExitSpan({
    required String traceId,
    required String traceSegmentId,
    required String operationName,
    required String peer,
    required DateTime start,
    required DateTime end,
    required bool isError,
    Map<String, String> tags = const {},
  }) {
    return NativeSpanData(
      traceId: traceId,
      traceSegmentId: traceSegmentId,
      spanId: 0,
      parentSpanId: -1,
      operationName: operationName,
      startTimeMs: start.millisecondsSinceEpoch,
      endTimeMs: end.millisecondsSinceEpoch,
      spanType: NativeSpanType.exit,
      spanLayer: NativeSpanLayer.http,
      componentId: config.componentId,
      isError: isError,
      peer: peer,
      tags: {
        'service.name': config.serviceName,
        'service.instance': config.serviceInstanceId,
        ...tags,
      },
    );
  }

  NativeSpanData buildLocalSpan({
    required String operationName,
    required Duration duration,
    required bool isError,
    Map<String, String> tags = const {},
    String? traceId,
    String? traceSegmentId,
  }) {
    final end = DateTime.now();
    final start = end.subtract(duration);
    final tid = traceId ?? _ids.traceId();
    final sid = traceSegmentId ?? _ids.segmentId();
    return NativeSpanData(
      traceId: tid,
      traceSegmentId: sid,
      spanId: 0,
      parentSpanId: -1,
      operationName: operationName,
      startTimeMs: start.millisecondsSinceEpoch,
      endTimeMs: end.millisecondsSinceEpoch,
      spanType: NativeSpanType.local,
      spanLayer: NativeSpanLayer.unknown,
      componentId: config.componentId,
      isError: isError,
      tags: {
        'service.name': config.serviceName,
        'service.instance': config.serviceInstanceId,
        ...tags,
      },
    );
  }
}
