/// OpenTelemetry OTLP/HTTP and SkyWalking native Segment agent for Dart & Flutter.
library;

export 'src/agent/agent_config.dart';
export 'src/agent/agent_mode.dart';
export 'src/agent/common/agent_meter.dart';
export 'src/agent/telemetry_channel.dart';
export 'src/agent/native/native_agent.dart';
export 'src/agent/native/native_config.dart';
export 'src/agent/native/skywalking_dart_layer.dart';
export 'src/agent/native/native_tracer.dart';
export 'src/agent/native/sw8_codec.dart';
export 'src/agent/native/sw8_context.dart';
export 'src/agent/native/sw8_propagator.dart';
export 'src/agent/skywalking_agent.dart';
export 'src/agent/common/id_generator.dart';
export 'src/agent/common/instrumented_client.dart';
export 'src/agent/otlp/otlp_agent.dart';
export 'src/agent/otlp/otlp_exporter_config.dart';
export 'src/agent/otlp/otlp_attribute.dart';
export 'src/agent/otlp/otlp_env.dart';
export 'src/agent/otlp/otlp_flutter.dart';
export 'src/agent/otlp/otlp_metrics_exporter.dart';
export 'src/agent/otlp/otlp_resource.dart';
export 'src/agent/otlp/otlp_span.dart';
export 'src/agent/otlp/otlp_trace_exporter.dart';
export 'src/agent/otlp/otlp_meter.dart';
export 'src/agent/otlp/otlp_tracer.dart';
export 'src/semconv.dart';
export 'src/skywalking.dart' show Skywalking;

// Backward-compatible re-exports (legacy import paths).
export 'src/config.dart';
export 'src/id_generator.dart';
export 'src/instrumented_client.dart';
export 'src/meter.dart';
export 'src/otlp_agent.dart';
export 'src/otlp_attribute.dart';
export 'src/otlp_env.dart';
export 'src/otlp_flutter.dart';
export 'src/otlp_metrics_exporter.dart';
export 'src/otlp_resource.dart';
export 'src/otlp_span.dart';
export 'src/otlp_trace_exporter.dart';
export 'src/tracer.dart';
