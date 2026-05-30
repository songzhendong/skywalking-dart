import 'dart:io';
import 'dart:isolate';

import 'package:grpc/grpc.dart';

import 'meter_proto_codec.dart';
import 'native_meter_sample.dart';

final _collectBatchMethod = ClientMethod<List<int>, List<int>>(
  '/skywalking.v3.MeterReportService/collectBatch',
  (value) => value,
  (value) => value,
);

/// gRPC client for `MeterReportService.collectBatch`.
class GrpcMeterClient {
  GrpcMeterClient({
    required String host,
    required int port,
    ClientChannel? channel,
  })  : _host = host,
        _port = port,
        _channel = channel ??
            ClientChannel(
              host,
              port: port,
              options: const ChannelOptions(
                credentials: ChannelCredentials.insecure(),
                connectTimeout: Duration(milliseconds: 5000),
                idleTimeout: Duration(milliseconds: 10000),
              ),
            );

  final String _host;
  final int _port;
  final ClientChannel _channel;
  bool _closed = false;

  Future<bool> collectBatch({
    required String service,
    required String serviceInstance,
    required List<NativeMeterSample> samples,
  }) async {
    if (samples.isEmpty) return true;
    final payload = MeterProtoCodec.encodeCollection(
      service: service,
      serviceInstance: serviceInstance,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      samples: samples,
    );
    if (!await _preflightTcp(_host, _port)) {
      // ignore: avoid_print
      print('[skywalking_dart] cannot reach $_host:$_port (OAP gRPC meter)');
      return false;
    }
    // ignore: avoid_print
    print(
      '[skywalking_dart] gRPC collectBatch (${payload.length} bytes, '
      '${samples.length} samples) ...',
    );
    try {
      return await Isolate.run(
        () => _grpcCollectBatch(_host, _port, payload),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // ignore: avoid_print
          print('[skywalking_dart] gRPC meter export timed out');
          return false;
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[skywalking_dart] meter export failed: $e');
      return false;
    }
  }

  static Future<bool> _preflightTcp(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      await socket.close();
      return true;
    } catch (_) {
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

Future<bool> _grpcCollectBatch(String host, int port, List<int> payload) async {
  final channel = ClientChannel(
    host,
    port: port,
    options: const ChannelOptions(
      credentials: ChannelCredentials.insecure(),
      connectTimeout: Duration(milliseconds: 5000),
      idleTimeout: Duration(milliseconds: 10000),
    ),
  );
  try {
    final client = Client(channel);
    final responses = client.$createStreamingCall<List<int>, List<int>>(
      _collectBatchMethod,
      Stream.value(payload),
      options: CallOptions(timeout: const Duration(seconds: 10)),
    );
    // Client-streaming RPC: consume server Commands response (see grpc-dart).
    await responses.toList();
    return true;
  } on GrpcError catch (e) {
    // ignore: avoid_print
    print('[skywalking_dart] meter gRPC ${e.codeName}: ${e.message}');
    return false;
  } finally {
    try {
      await channel.shutdown().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
