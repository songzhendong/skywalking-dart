import 'dart:async';

import 'grpc_management_client.dart';
import 'native_config.dart';
import 'skywalking_dart_layer.dart';

/// Registers the service/instance on OAP with layer [SkywalkingDartLayer.name].
class NativeServiceRegistration {
  NativeServiceRegistration(
    this.config, {
    GrpcManagementClient? client,
    this.keepAliveInterval = const Duration(seconds: 30),
    this.agentName = 'skywalking-dart',
    this.agentVersion = '0.1.1',
  }) : _client = client ??
            GrpcManagementClient(
              host: config.backendHostPort.$1,
              port: config.backendHostPort.$2,
            );

  final NativeAgentConfig config;
  final Duration keepAliveInterval;
  final String agentName;
  final String agentVersion;
  final GrpcManagementClient _client;

  Timer? _timer;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    await _registerOnce();
    _timer = Timer.periodic(keepAliveInterval, (_) => unawaited(_keepAlive()));
  }

  Future<void> _registerOnce() async {
    final okProps = await _client.reportInstanceProperties(
      service: config.serviceName,
      serviceInstance: config.serviceInstanceId,
      layer: config.serviceLayer,
      properties: {
        'agent.name': agentName,
        'agent.version': agentVersion,
        'language': 'dart',
      },
    );
    final okPing = await _client.keepAlive(
      service: config.serviceName,
      serviceInstance: config.serviceInstanceId,
      layer: config.serviceLayer,
    );
    if (okProps && okPing) {
      // ignore: avoid_print
      print(
        '[skywalking_dart] registered service=${config.serviceName} '
        'layer=${config.serviceLayer} instance=${config.serviceInstanceId}',
      );
    }
  }

  Future<void> _keepAlive() => _client.keepAlive(
        service: config.serviceName,
        serviceInstance: config.serviceInstanceId,
        layer: config.serviceLayer,
      );

  Future<void> close() async {
    _timer?.cancel();
    await _client.close();
    _started = false;
  }
}
