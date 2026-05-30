import 'package:skywalking_dart/src/agent/native/management_proto_codec.dart';
import 'package:skywalking_dart/src/agent/native/skywalking_dart_layer.dart';
import 'package:test/test.dart';

void main() {
  test('encodeInstancePingPkg includes layer field', () {
    final bytes = ManagementProtoCodec.encodeInstancePingPkg(
      service: 'my-app',
      serviceInstance: 'my-app@1',
      layer: SkywalkingDartLayer.name,
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes), contains('my-app'));
    expect(String.fromCharCodes(bytes), contains(SkywalkingDartLayer.name));
  });

  test('encodeInstanceProperties includes agent properties and layer', () {
    final bytes = ManagementProtoCodec.encodeInstanceProperties(
      service: 'my-app',
      serviceInstance: 'my-app@1',
      layer: SkywalkingDartLayer.name,
      properties: {'agent.name': 'skywalking-dart'},
    );
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes), contains('agent.name'));
    expect(String.fromCharCodes(bytes), contains('skywalking-dart'));
  });
}
