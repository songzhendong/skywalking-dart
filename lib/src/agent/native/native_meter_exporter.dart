import 'dart:async';

import '../common/agent_meter.dart';
import 'grpc_meter_client.dart';
import 'native_config.dart';
import 'native_meter_sample.dart';

String _nativeMetricName(String name) => name.replaceAll('.', '_');

Map<String, String> _nativeAttributes(
  NativeAgentConfig config,
  Map<String, String> attributes,
) {
  final out = <String, String>{
    // dart-native-meter.yaml filter: tags.service must be set.
    'service': config.serviceName,
  };
  for (final entry in attributes.entries) {
    out[entry.key.replaceAll('.', '_')] = entry.value;
  }
  return out;
}

/// Exports metrics via SkyWalking native gRPC `MeterReportService.collectBatch`.
class NativeMeterExporter {
  NativeMeterExporter(this.config, {GrpcMeterClient? client})
      : _client = client ??
            GrpcMeterClient(
              host: config.backendHostPort.$1,
              port: config.backendHostPort.$2,
            );

  final NativeAgentConfig config;
  final GrpcMeterClient _client;

  final List<NativeMeterSample> _queue = [];
  Timer? _timer;
  bool _closed = false;

  void start() {
    _timer ??= Timer.periodic(config.flushInterval, (_) => flush());
  }

  void recordCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
  }) {
    if (_closed || delta == 0) return;
    _queue.add(
      NativeMeterSample(
        name: _nativeMetricName(name),
        value: delta.toDouble(),
        attributes: _nativeAttributes(config, attributes),
      ),
    );
    if (_queue.length >= config.maxBatchSize) {
      unawaited(flush());
    }
  }

  void recordHistogram(
    String name,
    double value, {
    Map<String, String> attributes = const {},
  }) {
    if (_closed) return;
    final base = _nativeMetricName(name);
    final attrs = _nativeAttributes(config, attributes);
    _queue.add(NativeMeterSample(name: '${base}_sum', value: value, attributes: attrs));
    _queue.add(NativeMeterSample(name: '${base}_count', value: 1, attributes: attrs));
    if (_queue.length >= config.maxBatchSize) {
      unawaited(flush());
    }
  }

  Future<bool> flush() async {
    if (_closed || _queue.isEmpty) return true;
    final batch = List<NativeMeterSample>.from(_queue);
    _queue.clear();
    return _client.collectBatch(
      service: config.serviceName,
      serviceInstance: config.serviceInstanceId,
      samples: batch,
    );
  }

  Future<void> close() async {
    _closed = true;
    _timer?.cancel();
    await flush();
    await _client.close();
  }
}

/// Metrics API backed by native gRPC meter export.
class NativeMeter implements AgentMeter {
  NativeMeter(this._exporter);

  final NativeMeterExporter _exporter;

  @override
  void addCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
    String unit = '1',
  }) {
    _exporter.recordCounter(name, delta: delta, attributes: attributes);
  }

  @override
  void recordHistogram(
    String name,
    double value, {
    Map<String, String> attributes = const {},
    String unit = '1',
  }) {
    _exporter.recordHistogram(name, value, attributes: attributes);
  }

  @override
  void recordDuration(
    String name,
    Duration duration, {
    Map<String, String> attributes = const {},
  }) {
    recordHistogram(
      name,
      duration.inMicroseconds / 1000.0,
      attributes: attributes,
      unit: 'ms',
    );
  }
}
