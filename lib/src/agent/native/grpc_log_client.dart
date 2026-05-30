import 'dart:io';
import 'dart:isolate';

import 'package:grpc/grpc.dart';

import 'log_proto_codec.dart';
import 'native_log_entry.dart';

final _collectMethod = ClientMethod<List<int>, List<int>>(
  '/skywalking.v3.LogReportService/collect',
  (value) => value,
  (value) => value,
);

/// gRPC client for `LogReportService.collect`.
class GrpcLogClient {
  GrpcLogClient({
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

  Future<bool> collect({
    required String service,
    required String serviceInstance,
    required String layer,
    required List<NativeLogEntry> entries,
  }) async {
    if (entries.isEmpty) return true;
    final payloads = entries
        .map(
          (entry) => LogProtoCodec.encode(
            service: service,
            serviceInstance: serviceInstance,
            layer: layer,
            entry: entry,
          ),
        )
        .toList(growable: false);
    if (!await _preflightTcp(_host, _port)) {
      // ignore: avoid_print
      print('[skywalking_dart] cannot reach $_host:$_port (OAP gRPC log)');
      return false;
    }
    // ignore: avoid_print
    print('[skywalking_dart] gRPC log collect (${payloads.length} entries) ...');
    try {
      return await Isolate.run(
        () => _grpcCollect(_host, _port, payloads),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          // ignore: avoid_print
          print('[skywalking_dart] gRPC log export timed out');
          return false;
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[skywalking_dart] log export failed: $e');
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

Future<bool> _grpcCollect(
  String host,
  int port,
  List<List<int>> payloads,
) async {
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
      _collectMethod,
      Stream.fromIterable(payloads),
      options: CallOptions(timeout: const Duration(seconds: 10)),
    );
    await responses.toList();
    return true;
  } on GrpcError catch (e) {
    // ignore: avoid_print
    print('[skywalking_dart] log gRPC ${e.codeName}: ${e.message}');
    return false;
  } finally {
    try {
      await channel.shutdown().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
