import '../common/id_generator.dart';
import 'native_segment_ref.dart';
import 'native_span.dart';

/// Builds multi-service native segments for OAP topology smoke tests.
abstract final class TopologySimulator {
  static const defaultAppService = 'xt-open-app';
  static const defaultGatewayService = 'xt-gateway';
  static const defaultBackendService = 'xt-backend';
  static const defaultCacheService = 'xt-redis';
  static const defaultDatabaseService = 'mysql';

  /// One distributed trace: app → gateway → backend → redis + mysql.
  static List<NativeSpanData> buildChain({
    required IdGenerator ids,
    int componentId = 5012,
    String appService = defaultAppService,
    String gatewayService = defaultGatewayService,
    String backendService = defaultBackendService,
    String cacheService = defaultCacheService,
    String databasePeer = defaultDatabaseService,
    String? traceId,
    DateTime? baseTime,
  }) {
    final tid = traceId ?? ids.traceId();
    final t0 = (baseTime ?? DateTime.now()).millisecondsSinceEpoch;

    final appSeg = ids.segmentId();
    final gwSeg = ids.segmentId();
    final beSeg = ids.segmentId();

    const appInst = 'verify-app-1';
    const gwInst = 'verify-gateway-1';
    const beInst = 'verify-backend-1';

    const feedOp = 'GET:/xt/app/feed/list';
    const gwRouteOp = 'SpringCloud/gateway/route';
    const beQueryOp = 'Mysql/JDBC/Query';
    const cacheOp = 'Redis/GET';

    final appExitPeer = 'xt-gateway:8080';
    final gwExitPeer = 'xt-backend:8080';
    final beCachePeer = 'xt-redis:6379';
    final beDbPeer = '$databasePeer:3306';

  // --- xt-open-app ---
    final appLocal = _span(
      traceId: tid,
      traceSegmentId: appSeg,
      serviceName: appService,
      serviceInstance: appInst,
      spanId: 0,
      parentSpanId: -1,
      spanType: NativeSpanType.local,
      spanLayer: NativeSpanLayer.unknown,
      operationName: 'Home/feed.load',
      startTimeMs: t0,
      endTimeMs: t0 + 8,
      componentId: componentId,
    );
    final appExit = _span(
      traceId: tid,
      traceSegmentId: appSeg,
      serviceName: appService,
      serviceInstance: appInst,
      spanId: 1,
      parentSpanId: 0,
      spanType: NativeSpanType.exit,
      spanLayer: NativeSpanLayer.http,
      operationName: feedOp,
      startTimeMs: t0 + 8,
      endTimeMs: t0 + 42,
      peer: appExitPeer,
      componentId: componentId,
    );

    // --- xt-gateway ---
    final gwEntry = _span(
      traceId: tid,
      traceSegmentId: gwSeg,
      serviceName: gatewayService,
      serviceInstance: gwInst,
      spanId: 0,
      parentSpanId: -1,
      spanType: NativeSpanType.entry,
      spanLayer: NativeSpanLayer.http,
      operationName: feedOp,
      startTimeMs: t0 + 42,
      endTimeMs: t0 + 46,
      componentId: componentId,
      refs: [
        NativeSegmentRef(
          traceId: tid,
          parentTraceSegmentId: appSeg,
          parentSpanId: 1,
          parentService: appService,
          parentServiceInstance: appInst,
          parentEndpoint: feedOp,
          networkAddressUsedAtPeer: appExitPeer,
        ),
      ],
    );
    final gwExit = _span(
      traceId: tid,
      traceSegmentId: gwSeg,
      serviceName: gatewayService,
      serviceInstance: gwInst,
      spanId: 1,
      parentSpanId: 0,
      spanType: NativeSpanType.exit,
      spanLayer: NativeSpanLayer.http,
      operationName: gwRouteOp,
      startTimeMs: t0 + 46,
      endTimeMs: t0 + 78,
      peer: gwExitPeer,
      componentId: componentId,
    );

    // --- xt-backend ---
    final beEntry = _span(
      traceId: tid,
      traceSegmentId: beSeg,
      serviceName: backendService,
      serviceInstance: beInst,
      spanId: 0,
      parentSpanId: -1,
      spanType: NativeSpanType.entry,
      spanLayer: NativeSpanLayer.http,
      operationName: '/xt/app/feed/list',
      startTimeMs: t0 + 78,
      endTimeMs: t0 + 82,
      componentId: componentId,
      refs: [
        NativeSegmentRef(
          traceId: tid,
          parentTraceSegmentId: gwSeg,
          parentSpanId: 1,
          parentService: gatewayService,
          parentServiceInstance: gwInst,
          parentEndpoint: gwRouteOp,
          networkAddressUsedAtPeer: gwExitPeer,
        ),
      ],
    );
    final beCacheExit = _span(
      traceId: tid,
      traceSegmentId: beSeg,
      serviceName: backendService,
      serviceInstance: beInst,
      spanId: 1,
      parentSpanId: 0,
      spanType: NativeSpanType.exit,
      spanLayer: NativeSpanLayer.http,
      operationName: cacheOp,
      startTimeMs: t0 + 82,
      endTimeMs: t0 + 95,
      peer: beCachePeer,
      componentId: componentId,
    );
    final beDbExit = _span(
      traceId: tid,
      traceSegmentId: beSeg,
      serviceName: backendService,
      serviceInstance: beInst,
      spanId: 2,
      parentSpanId: 0,
      spanType: NativeSpanType.exit,
      spanLayer: NativeSpanLayer.http,
      operationName: beQueryOp,
      startTimeMs: t0 + 95,
      endTimeMs: t0 + 120,
      peer: beDbPeer,
      componentId: componentId,
    );

    // Virtual downstream nodes (peer-only segments) for cache + DB layers.
    final cacheSeg = ids.segmentId();
    final dbSeg = ids.segmentId();

    final cacheEntry = _span(
      traceId: tid,
      traceSegmentId: cacheSeg,
      serviceName: cacheService,
      serviceInstance: 'verify-redis-1',
      spanId: 0,
      parentSpanId: -1,
      spanType: NativeSpanType.entry,
      spanLayer: NativeSpanLayer.http,
      operationName: cacheOp,
      startTimeMs: t0 + 95,
      endTimeMs: t0 + 98,
      componentId: componentId,
      refs: [
        NativeSegmentRef(
          traceId: tid,
          parentTraceSegmentId: beSeg,
          parentSpanId: 1,
          parentService: backendService,
          parentServiceInstance: beInst,
          parentEndpoint: cacheOp,
          networkAddressUsedAtPeer: beCachePeer,
        ),
      ],
    );

    final dbEntry = _span(
      traceId: tid,
      traceSegmentId: dbSeg,
      serviceName: databasePeer,
      serviceInstance: 'verify-mysql-1',
      spanId: 0,
      parentSpanId: -1,
      spanType: NativeSpanType.entry,
      spanLayer: NativeSpanLayer.http,
      operationName: beQueryOp,
      startTimeMs: t0 + 120,
      endTimeMs: t0 + 125,
      componentId: componentId,
      refs: [
        NativeSegmentRef(
          traceId: tid,
          parentTraceSegmentId: beSeg,
          parentSpanId: 2,
          parentService: backendService,
          parentServiceInstance: beInst,
          parentEndpoint: beQueryOp,
          networkAddressUsedAtPeer: beDbPeer,
        ),
      ],
    );

    return [
      appLocal,
      appExit,
      gwEntry,
      gwExit,
      beEntry,
      beCacheExit,
      beDbExit,
      cacheEntry,
      dbEntry,
    ];
  }

  /// Multiple traces spaced in time so Horizon can aggregate RPM/SLA.
  static List<NativeSpanData> buildBurst({
    required IdGenerator ids,
    int traceCount = 8,
    int componentId = 5012,
    String appService = defaultAppService,
    String gatewayService = defaultGatewayService,
    String backendService = defaultBackendService,
    String cacheService = defaultCacheService,
    String databasePeer = defaultDatabaseService,
  }) {
    final all = <NativeSpanData>[];
    final base = DateTime.now().subtract(
      Duration(milliseconds: traceCount * 120),
    );
    for (var i = 0; i < traceCount; i++) {
      all.addAll(
        buildChain(
          ids: ids,
          componentId: componentId,
          appService: appService,
          gatewayService: gatewayService,
          backendService: backendService,
          cacheService: cacheService,
          databasePeer: databasePeer,
          baseTime: base.add(Duration(milliseconds: i * 150)),
        ),
      );
    }
    return all;
  }

  static NativeSpanData _span({
    required String traceId,
    required String traceSegmentId,
    required String serviceName,
    required String serviceInstance,
    required int spanId,
    required int parentSpanId,
    required NativeSpanType spanType,
    required NativeSpanLayer spanLayer,
    required String operationName,
    required int startTimeMs,
    required int endTimeMs,
    required int componentId,
    String peer = '',
    List<NativeSegmentRef> refs = const [],
    bool isError = false,
  }) {
    return NativeSpanData(
      traceId: traceId,
      traceSegmentId: traceSegmentId,
      spanId: spanId,
      parentSpanId: parentSpanId,
      operationName: operationName,
      startTimeMs: startTimeMs,
      endTimeMs: endTimeMs,
      spanType: spanType,
      spanLayer: spanLayer,
      componentId: componentId,
      isError: isError,
      peer: peer,
      refs: refs,
      tags: {
        'service.name': serviceName,
        'service.instance': serviceInstance,
      },
    );
  }
}
