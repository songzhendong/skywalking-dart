import 'dart:io';

import 'skywalking_dart_layer.dart';

/// SkyWalking native agent (Segment gRPC) configuration.
class NativeAgentConfig {
  const NativeAgentConfig({
    required this.serviceName,
    this.backendAddress = '127.0.0.1:11800',
    this.serviceInstance,
    this.serviceVersion = 'unknown',
    this.serviceLayer = SkywalkingDartLayer.name,
    this.flushInterval = const Duration(seconds: 5),
    this.maxBatchSize = 32,
    this.maxQueueSize = 512,
    this.logSampleRate = 1.0,
    this.tracesEnabled = true,
    this.componentId = 5019,
  });

  final String serviceName;
  final String backendAddress;
  final String? serviceInstance;
  final String serviceVersion;
  /// OAP layer for ManagementService registration (default [SkywalkingDartLayer.name]).
  final String serviceLayer;
  final Duration flushInterval;
  final int maxBatchSize;
  /// Max pending items per exporter queue; oldest dropped when exceeded.
  final int maxQueueSize;
  /// Fraction of non-ERROR logs to keep in `(0,1]`; ERROR always kept.
  final double logSampleRate;
  final bool tracesEnabled;
  final int componentId;

  /// Browser-style default: static [serviceVersion], not per-process PID.
  String get serviceInstanceId {
    final explicit = serviceInstance?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }
    if (serviceVersion != 'unknown' && serviceVersion.trim().isNotEmpty) {
      return serviceVersion;
    }
    return 'unknown';
  }

  (String host, int port) get backendHostPort {
    final raw = backendAddress.trim();
    if (raw.contains('://')) {
      final uri = Uri.parse(raw);
      return (uri.host, uri.port == 0 ? 11800 : uri.port);
    }
    final parts = raw.split(':');
    if (parts.length == 2) {
      return (parts[0], int.tryParse(parts[1]) ?? 11800);
    }
    return (raw, 11800);
  }

  factory NativeAgentConfig.fromEnvironment({
    Map<String, String> dartDefines = const {},
    String defaultBackend = '127.0.0.1:11800',
    String defaultServiceName = 'unknown_service',
    bool tracesEnabled = true,
  }) {
    String? pick(List<String> keys) {
      for (final key in keys) {
        final v = dartDefines[key]?.trim();
        if (v != null && v.isNotEmpty) return v;
        final compiled = String.fromEnvironment(key).trim();
        if (compiled.isNotEmpty) return compiled;
        final env = Platform.environment[key]?.trim();
        if (env != null && env.isNotEmpty) return env;
      }
      return null;
    }

    final lanHost = pick(const ['SKYWALKING_LAN_HOST']);
    var backend = pick(const [
          'SW_AGENT_COLLECTOR_BACKEND_SERVICES',
          'SKYWALKING_BACKEND_SERVICES',
          'SKYWALKING_NATIVE_BACKEND',
        ]) ??
        defaultBackend;

    // Peanut-shell / DDNS hostnames rarely expose gRPC 11800 — prefer LAN override.
    if (lanHost != null && _looksLikeTunnelHost(_hostOfBackend(backend))) {
      backend = '$lanHost:11800';
    } else if (_looksLikeTunnelHost(_hostOfBackend(backend)) &&
        lanHost == null) {
      backend = defaultBackend;
      if (_looksLikeTunnelHost(_hostOfBackend(backend))) {
        backend = '127.0.0.1:11800';
      }
    }

    final serviceName = pick(const [
          'SW_AGENT_NAME',
          'SKYWALKING_SERVICE_NAME',
          'OTEL_SERVICE_NAME',
          'SERVICE_NAME',
        ]) ??
        defaultServiceName;

    final layer = pick(const [
          'SW_AGENT_LAYER',
          'SKYWALKING_SERVICE_LAYER',
        ]) ??
        SkywalkingDartLayer.name;

    final serviceVersion = pick(const [
          'OTEL_SERVICE_VERSION',
          'APP_VERSION',
          'SKYWALKING_SERVICE_VERSION',
        ]) ??
        'unknown';

    final flushSec = _parsePositiveInt(
      pick(const [
        'SKYWALKING_FLUSH_INTERVAL_SEC',
        'SW_AGENT_FLUSH_INTERVAL_SEC',
      ]),
      fallback: 5,
    );
    final maxBatch = _parsePositiveInt(
      pick(const ['SKYWALKING_MAX_BATCH_SIZE']),
      fallback: 32,
    );
    final maxQueue = _parsePositiveInt(
      pick(const ['SKYWALKING_MAX_QUEUE_SIZE']),
      fallback: 512,
    );
    final logSample = _parseSampleRate(
      pick(const ['SKYWALKING_LOG_SAMPLE_RATE']),
      fallback: 1.0,
    );

    return NativeAgentConfig(
      serviceName: serviceName,
      backendAddress: backend,
      serviceInstance: pick(const ['SW_AGENT_INSTANCE_NAME']),
      serviceVersion: serviceVersion,
      serviceLayer: layer,
      flushInterval: Duration(seconds: flushSec),
      maxBatchSize: maxBatch,
      maxQueueSize: maxQueue,
      logSampleRate: logSample,
      tracesEnabled: tracesEnabled,
    );
  }

  static int _parsePositiveInt(String? raw, {required int fallback}) {
    if (raw == null || raw.isEmpty) return fallback;
    final n = int.tryParse(raw.trim());
    if (n == null || n < 1) return fallback;
    return n;
  }

  static double _parseSampleRate(String? raw, {required double fallback}) {
    if (raw == null || raw.isEmpty) return fallback;
    final n = double.tryParse(raw.trim());
    if (n == null) return fallback;
    if (n <= 0) return 0;
    if (n >= 1) return 1;
    return n;
  }

  static bool _looksLikeTunnelHost(String host) {
    final h = host.toLowerCase();
    return h.contains('vicp.fun') || h.contains('oray.net') || h.contains('3322.net');
  }

  static String _hostOfBackend(String backend) {
    final raw = backend.trim();
    if (raw.contains('://')) {
      return Uri.parse(raw).host;
    }
    final parts = raw.split(':');
    return parts.isNotEmpty ? parts[0] : raw;
  }
}
