import 'package:grpc/grpc.dart';

import 'management_proto_codec.dart';

final _reportInstancePropertiesMethod = ClientMethod<List<int>, List<int>>(
  '/skywalking.v3.ManagementService/reportInstanceProperties',
  (value) => value,
  (value) => value,
);

final _keepAliveMethod = ClientMethod<List<int>, List<int>>(
  '/skywalking.v3.ManagementService/keepAlive',
  (value) => value,
  (value) => value,
);

/// gRPC client for `ManagementService` (instance registration + layer).
class GrpcManagementClient {
  GrpcManagementClient({
    required String host,
    required int port,
    ClientChannel? channel,
  })  : _channel = channel ??
            ClientChannel(
              host,
              port: port,
              options: const ChannelOptions(
                credentials: ChannelCredentials.insecure(),
                connectTimeout: Duration(milliseconds: 5000),
                idleTimeout: Duration(milliseconds: 10000),
              ),
            );

  final ClientChannel _channel;
  bool _closed = false;

  Future<bool> reportInstanceProperties({
    required String service,
    required String serviceInstance,
    required String layer,
    Map<String, String> properties = const {},
  }) {
    final payload = ManagementProtoCodec.encodeInstanceProperties(
      service: service,
      serviceInstance: serviceInstance,
      layer: layer,
      properties: properties,
    );
    return _unary(_reportInstancePropertiesMethod, payload);
  }

  Future<bool> keepAlive({
    required String service,
    required String serviceInstance,
    required String layer,
  }) {
    final payload = ManagementProtoCodec.encodeInstancePingPkg(
      service: service,
      serviceInstance: serviceInstance,
      layer: layer,
    );
    return _unary(_keepAliveMethod, payload);
  }

  Future<bool> _unary(ClientMethod<List<int>, List<int>> method, List<int> payload) async {
    if (_closed) return false;
    try {
      final client = Client(_channel);
      await client.$createUnaryCall<List<int>, List<int>>(
        method,
        payload,
        options: CallOptions(timeout: const Duration(seconds: 10)),
      );
      return true;
    } on GrpcError catch (e) {
      // ignore: avoid_print
      print('[skywalking_dart] management gRPC ${e.codeName}: ${e.message}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('[skywalking_dart] management call failed: $e');
      return false;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _channel.shutdown().timeout(const Duration(seconds: 3));
    } catch (_) {}
  }
}
