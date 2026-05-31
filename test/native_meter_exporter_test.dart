import 'package:skywalking_dart/src/agent/native/grpc_meter_client.dart';
import 'package:skywalking_dart/src/agent/native/native_config.dart';
import 'package:skywalking_dart/src/agent/native/native_meter_exporter.dart';
import 'package:skywalking_dart/src/agent/native/native_meter_sample.dart';
import 'package:test/test.dart';

import 'support/test_native_clients.dart';

void main() {
  test('recordCounter omits service label; batch carries service at MeterData level',
      () async {
    final config = NativeAgentConfig(
      serviceName: 'xt-open-app',
      backendAddress: '127.0.0.1:9',
      serviceInstance: 'test-inst',
      maxBatchSize: 2,
    );
    final client = CapturingMeterClient();
    final exporter = NativeMeterExporter(config, client: client);

    exporter.recordCounter('app.screen.views', attributes: {'screen_name': 'tab.home'});
    expect(client.batches, isEmpty);

    exporter.recordCounter('app.session.start');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(client.batches, hasLength(1));
    expect(client.lastService, 'xt-open-app');
    expect(client.lastServiceInstance, 'test-inst');
    final samples = client.batches.single;
    expect(samples.length, greaterThanOrEqualTo(2));
    expect(samples.every((s) => !s.attributes.containsKey('service')), isTrue);
    expect(samples.every((s) => !s.attributes.containsKey('instance')), isTrue);
  });

  test('strips service/instance from user attributes to avoid OAP duplicate key',
      () async {
    final config = NativeAgentConfig(
      serviceName: 'xt-open-app',
      backendAddress: '127.0.0.1:9',
      maxBatchSize: 1,
    );
    final client = CapturingMeterClient();
    final exporter = NativeMeterExporter(config, client: client);

    exporter.recordCounter(
      'app.user.action',
      attributes: {'service': 'other', 'instance': 'x', 'action': 'tap'},
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final sample = client.batches.single.single;
    expect(sample.attributes, {'action': 'tap'});
  });
}

/// Captures meter batches without network.
class CapturingMeterClient extends GrpcMeterClient {
  CapturingMeterClient() : super(host: '127.0.0.1', port: 9);

  final List<List<NativeMeterSample>> batches = [];
  String? lastService;
  String? lastServiceInstance;

  @override
  Future<bool> collectBatch({
    required String service,
    required String serviceInstance,
    required List<NativeMeterSample> samples,
  }) async {
    lastService = service;
    lastServiceInstance = serviceInstance;
    batches.add(List.from(samples));
    return true;
  }
}
