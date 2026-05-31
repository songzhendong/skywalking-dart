import 'package:skywalking_dart/src/agent/common/id_generator.dart';
import 'package:skywalking_dart/src/agent/native/segment_proto_codec.dart';
import 'support/topology_simulator.dart';
import 'package:test/test.dart';

void main() {
  test('buildChain encodes multiple services without huge payload', () {
    final spans = TopologySimulator.buildChain(ids: IdGenerator());
    expect(spans.length, 9);

    final services = spans
        .map((s) => s.tags['service.name'])
        .whereType<String>()
        .toSet();
    expect(
      services,
      containsAll([
        'xt-open-app',
        'xt-gateway',
        'xt-backend',
        'xt-redis',
        'mysql',
      ]),
    );

    final payload = SegmentProtoCodec.encodeCollection(spans);
    expect(payload.length, greaterThan(200));
    expect(payload.length, lessThan(500000));
  });

  test('buildBurst scales with trace count', () {
    final spans = TopologySimulator.buildBurst(ids: IdGenerator(), traceCount: 3);
    expect(spans.length, 27);
  });
}
