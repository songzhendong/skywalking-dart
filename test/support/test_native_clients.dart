import 'package:skywalking_dart/src/agent/native/grpc_log_client.dart';
import 'package:skywalking_dart/src/agent/native/grpc_management_client.dart';
import 'package:skywalking_dart/src/agent/native/grpc_trace_client.dart';
import 'package:skywalking_dart/src/agent/native/log_proto_codec.dart';
import 'package:skywalking_dart/src/agent/native/native_log_entry.dart';
import 'package:skywalking_dart/src/agent/native/native_span.dart';

/// No network: accepts trace batches in tests.
class NoopTraceClient extends GrpcTraceClient {
  NoopTraceClient() : super(host: '127.0.0.1', port: 9);

  @override
  Future<bool> collectInSync(List<NativeSpanData> spans) async => true;
}

/// No network: captures log entries and encoded payloads.
class CapturingLogClient extends GrpcLogClient {
  CapturingLogClient() : super(host: '127.0.0.1', port: 9);

  final List<NativeLogEntry> entries = [];
  final List<List<int>> payloads = [];

  @override
  Future<bool> collect({
    required String service,
    required String serviceInstance,
    required String layer,
    required List<NativeLogEntry> entries,
  }) async {
    this.entries.addAll(entries);
    for (final entry in entries) {
      payloads.add(
        LogProtoCodec.encode(
          service: service,
          serviceInstance: serviceInstance,
          layer: layer,
          entry: entry,
        ),
      );
    }
    return true;
  }
}

/// No network: skips OAP registration.
class NoopManagementClient extends GrpcManagementClient {
  NoopManagementClient() : super(host: '127.0.0.1', port: 9);

  @override
  Future<bool> reportInstanceProperties({
    required String service,
    required String serviceInstance,
    required String layer,
    Map<String, String> properties = const {},
  }) async =>
      true;

  @override
  Future<bool> keepAlive({
    required String service,
    required String serviceInstance,
    required String layer,
  }) async =>
      true;
}
