import 'segment_exporter.dart';

/// Native SkyWalking tracer (segment-based).
class NativeTracer {
  NativeTracer(this._exporter);

  final SegmentExporter _exporter;

  void recordSpan({
    required String name,
    Duration duration = Duration.zero,
    Map<String, String> attributes = const {},
    bool isError = false,
  }) {
    _exporter.enqueue(
      _exporter.buildLocalSpan(
        operationName: name,
        duration: duration,
        isError: isError,
        tags: attributes,
      ),
    );
  }

  Future<T> withSpan<T>(
    String name,
    Future<T> Function() action, {
    Map<String, String> attributes = const {},
  }) async {
    final start = DateTime.now();
    try {
      final result = await action();
      final elapsed = DateTime.now().difference(start);
      recordSpan(
        name: name,
        duration: elapsed,
        attributes: attributes,
        isError: false,
      );
      return result;
    } catch (e) {
      final elapsed = DateTime.now().difference(start);
      recordSpan(
        name: name,
        duration: elapsed,
        attributes: {
          ...attributes,
          'exception.type': e.runtimeType.toString(),
          'exception.message': e.toString(),
        },
        isError: true,
      );
      rethrow;
    }
  }
}
