/// Cross-segment reference for native SkyWalking spans (`SegmentReference`).
class NativeSegmentRef {
  const NativeSegmentRef({
    this.refType = NativeRefType.crossProcess,
    required this.traceId,
    required this.parentTraceSegmentId,
    required this.parentSpanId,
    required this.parentService,
    required this.parentServiceInstance,
    required this.parentEndpoint,
    required this.networkAddressUsedAtPeer,
  });

  final NativeRefType refType;
  final String traceId;
  final String parentTraceSegmentId;
  final int parentSpanId;
  final String parentService;
  final String parentServiceInstance;
  final String parentEndpoint;
  final String networkAddressUsedAtPeer;
}

enum NativeRefType {
  crossProcess(0),
  crossThread(1);

  const NativeRefType(this.wire);
  final int wire;
}
