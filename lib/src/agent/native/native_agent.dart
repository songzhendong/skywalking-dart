import 'dart:async';

import 'package:http/http.dart' as http;

import '../common/agent_meter.dart';
import '../common/instrumented_client.dart';
import 'native_config.dart';
import 'native_log_entry.dart';
import 'native_log_exporter.dart';
import 'native_meter_exporter.dart';
import 'native_service_registration.dart';
import 'native_tracer.dart';
import 'segment_exporter.dart';

/// SkyWalking native agent (gRPC Segment / Meter / Log).
class NativeAgent {
  NativeAgent._(
    this.config,
    this._segments,
    this._registration,
    this._meters,
    this._logs,
  );

  static NativeAgent? _instance;

  final NativeAgentConfig config;
  final SegmentExporter? _segments;
  final NativeServiceRegistration _registration;
  final NativeMeterExporter? _meters;
  final NativeLogExporter? _logs;
  NativeTracer? _tracer;
  NativeMeter? _meter;

  static NativeAgent init(
    NativeAgentConfig config, {
    bool periodicFlush = true,
    bool tracesEnabled = true,
    bool metricsEnabled = false,
    bool logsEnabled = false,
  }) {
    if (_instance != null) return _instance!;
    SegmentExporter? segments;
    if (tracesEnabled && config.tracesEnabled) {
      segments = SegmentExporter(config);
      if (periodicFlush) {
        segments.start();
      }
    }
    NativeMeterExporter? meters;
    if (metricsEnabled) {
      meters = NativeMeterExporter(config);
      if (periodicFlush) {
        meters.start();
      }
    }
    NativeLogExporter? logs;
    if (logsEnabled) {
      logs = NativeLogExporter(config);
      if (periodicFlush) {
        logs.start();
      }
    }
    final registration = NativeServiceRegistration(config);
    unawaited(registration.start());
    _instance = NativeAgent._(config, segments, registration, meters, logs);
    return _instance!;
  }

  static NativeAgent get instance {
    final i = _instance;
    if (i == null) {
      throw StateError('Call NativeAgent.init() before using the agent.');
    }
    return i;
  }

  static bool get isInitialized => _instance != null;

  NativeTracer get tracer {
    final exporter = _segments;
    if (exporter == null) {
      throw StateError('Native traces are disabled in config');
    }
    return _tracer ??= NativeTracer(exporter);
  }

  SegmentExporter? get segmentExporter => _segments;

  AgentMeter? get meterIfEnabled {
    final m = _meters;
    if (m == null) return null;
    return _meter ??= NativeMeter(m);
  }

  NativeLogExporter? get logExporter => _logs;

  void reportLog({
    required String message,
    String endpoint = '',
    Map<String, String> tags = const {},
    String? traceId,
    String? traceSegmentId,
    int? spanId,
    String bodyType = 'text',
  }) {
    final exporter = _logs;
    if (exporter == null) return;

    var resolvedTraceId = traceId;
    var resolvedSegmentId = traceSegmentId;
    var resolvedSpanId = spanId;
    final active = _tracer?.lastSpanContext;
    if (active != null && active.isValid) {
      resolvedTraceId ??= active.traceId;
      resolvedSegmentId ??= active.traceSegmentId;
      resolvedSpanId ??= active.spanId;
      endpoint = endpoint.isNotEmpty ? endpoint : active.operationName;
    }

    exporter.enqueue(
      NativeLogEntry(
        message: message,
        endpoint: endpoint,
        tags: tags,
        traceId: resolvedTraceId,
        traceSegmentId: resolvedSegmentId,
        spanId: resolvedSpanId,
        bodyType: bodyType,
      ),
    );
  }

  InstrumentedClient httpClient({
    http.Client? inner,
    bool injectSw8 = true,
    AgentMeter? meter,
  }) {
    return InstrumentedClient(
      inner: inner ?? http.Client(),
      nativeExporter: _segments,
      nativeConfig: config,
      meter: meter ?? meterIfEnabled,
      injectSw8: injectSw8,
    );
  }

  Future<void> flush() async {
    await _segments?.flush();
    await _meters?.flush();
    await _logs?.flush();
  }

  Future<void> shutdown() async {
    await _segments?.close();
    await _meters?.close();
    await _logs?.close();
    await _registration.close();
    _instance = null;
  }
}
