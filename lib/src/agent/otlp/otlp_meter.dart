import 'otlp_metrics_exporter.dart';
import '../common/agent_meter.dart';

/// Metrics API (OpenTelemetry Meter-like).
class OtlpMeter implements AgentMeter {
  OtlpMeter(this._exporter);

  final OtlpMetricsExporter _exporter;

  @override
  void addCounter(
    String name, {
    int delta = 1,
    Map<String, String> attributes = const {},
    String unit = '1',
  }) {
    _exporter.recordCounter(
      name,
      delta: delta,
      attributes: attributes,
      unit: unit,
    );
  }

  @override
  void recordHistogram(
    String name,
    double value, {
    Map<String, String> attributes = const {},
    String unit = '1',
  }) {
    _exporter.recordHistogram(
      name,
      value,
      attributes: attributes,
      unit: unit,
    );
  }

  @override
  void recordDuration(
    String name,
    Duration duration, {
    Map<String, String> attributes = const {},
  }) {
    recordHistogram(
      name,
      duration.inMicroseconds / 1000.0,
      attributes: attributes,
      unit: 'ms',
    );
  }

  @Deprecated('Use recordDuration')
  void recordHistogramMs(
    String name,
    double milliseconds, {
    Map<String, String> attributes = const {},
  }) =>
      recordHistogram(
        name,
        milliseconds,
        attributes: attributes,
        unit: 'ms',
      );
}
