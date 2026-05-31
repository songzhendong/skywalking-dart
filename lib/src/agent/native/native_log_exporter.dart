import 'dart:async';

import 'grpc_log_client.dart';
import 'native_config.dart';
import 'native_export_queue.dart';
import 'native_log_entry.dart';

/// Exports logs via SkyWalking native gRPC `LogReportService.collect`.
class NativeLogExporter {
  NativeLogExporter(this.config, {GrpcLogClient? client})
      : _client = client ??
            GrpcLogClient(
              host: config.backendHostPort.$1,
              port: config.backendHostPort.$2,
            );

  final NativeAgentConfig config;
  final GrpcLogClient _client;

  final List<NativeLogEntry> _queue = [];
  Timer? _timer;
  bool _closed = false;

  void start() {
    _timer ??= Timer.periodic(config.flushInterval, (_) => flush());
  }

  void enqueue(NativeLogEntry entry) {
    if (_closed) return;
    if (!shouldSampleLog(entry, config.logSampleRate)) return;
    enqueueCapped(
      _queue,
      entry,
      maxQueueSize: config.maxQueueSize,
      maxBatchSize: config.maxBatchSize,
      onReachBatchSize: () => unawaited(flush()),
    );
  }

  Future<bool> flush() async {
    if (_closed || _queue.isEmpty) return true;
    final batch = List<NativeLogEntry>.from(_queue);
    _queue.clear();
    return _client.collect(
      service: config.serviceName,
      serviceInstance: config.serviceInstanceId,
      layer: config.serviceLayer,
      entries: batch,
    );
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await flush();
    await _client.close();
  }
}
