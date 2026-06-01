import 'dart:io';
import 'dart:isolate';

import 'package:grpc/grpc.dart';

import 'native_span.dart';
import 'segment_proto_codec.dart';

final _collectInSyncMethod = ClientMethod<List<int>, List<int>>(
  '/skywalking.v3.TraceSegmentReportService/collectInSync',
  (value) => value,
  (value) => value,
);

/// gRPC client for `TraceSegmentReportService.collectInSync`.
class GrpcTraceClient {
  GrpcTraceClient({
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


  Future<bool> collectInSync(List<NativeSpanData> spans) async {
    if (spans.isEmpty) return true;
    final payload = SegmentProtoCodec.encodeCollection(spans);
    // ignore: avoid_print
    print('[skywalking_dart] tcp preflight $_host:$_port ...');
    if (!await _preflightTcp(_host, _port)) {
      // ignore: avoid_print
      print('[skywalking_dart] cannot reach $_host:$_port (OAP gRPC)');
      return false;
    }
    // ignore: avoid_print
    print('[skywalking_dart] gRPC collectInSync (${payload.length} bytes) ...');
    // gRPC can block the Dart event loop; run in a short-lived isolate so CLI
    // timeouts still fire.
    try {
      return await Isolate.run(
        () => _grpcCollectInSync(_host, _port, payload),
      ).timeout(
        const Duration(seconds: 25),
        onTimeout: () {
          // ignore: avoid_print
          print(
            '[skywalking_dart] gRPC export timed out (OAP may reject payload or hang)',
          );
          return false;
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[skywalking_dart] export failed: $e');
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
    } catch (_) {
      // Best-effort shutdown; do not block CLI exit.
    }
  }
}

/// Top-level for [Isolate.run] — must not capture instance state.
Future<bool> _grpcCollectInSync(String host, int port, List<int> payload) async {
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
    await client.$createUnaryCall<List<int>, List<int>>(
      _collectInSyncMethod,
      payload,
      options: CallOptions(timeout: const Duration(seconds: 15)),
    );
    return true;
  } on GrpcError catch (e) {
    // ignore: avoid_print
    print('[skywalking_dart] gRPC error: ${e.codeName} ${e.message}');
    return false;
  } finally {
    try {
      await channel.shutdown().timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
