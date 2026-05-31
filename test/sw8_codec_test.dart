import 'package:skywalking_dart/skywalking_dart.dart';
import 'package:test/test.dart';

void main() {
  test('sw8 round-trip', () {
    const ctx = Sw8Context(
      sample: 1,
      traceId: 'abc123',
      traceSegmentId: 'seg456',
      spanId: 0,
      service: 'my-app',
      serviceInstance: 'inst1',
      endpoint: 'GET /xt/user',
      peer: 'api.example.com:443',
    );
    final header = Sw8Codec.encode(ctx);
    final decoded = Sw8Codec.decode(header);
    expect(decoded, isNotNull);
    expect(decoded!.traceId, ctx.traceId);
    expect(decoded.traceSegmentId, ctx.traceSegmentId);
    expect(decoded.spanId, ctx.spanId);
    expect(decoded.service, ctx.service);
    expect(decoded.endpoint, ctx.endpoint);
    expect(decoded.peer, ctx.peer);
  });
}
