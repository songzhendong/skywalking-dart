import 'package:skywalking_dart/src/agent/native/native_config.dart';
import 'package:skywalking_dart/src/agent/native/native_export_queue.dart';
import 'package:skywalking_dart/src/agent/native/native_log_entry.dart';
import 'package:test/test.dart';

void main() {
  test('fromEnvironment parses flush, batch, queue, log sample', () {
    final cfg = NativeAgentConfig.fromEnvironment(
      dartDefines: const {
        'SKYWALKING_FLUSH_INTERVAL_SEC': '10',
        'SKYWALKING_MAX_BATCH_SIZE': '64',
        'SKYWALKING_MAX_QUEUE_SIZE': '128',
        'SKYWALKING_LOG_SAMPLE_RATE': '0.25',
      },
    );
    expect(cfg.flushInterval, const Duration(seconds: 10));
    expect(cfg.maxBatchSize, 64);
    expect(cfg.maxQueueSize, 128);
    expect(cfg.logSampleRate, 0.25);
  });

  test('enqueueCapped drops oldest when over maxQueueSize', () {
    final q = <int>[];
    for (var i = 0; i < 5; i++) {
      enqueueCapped(q, i, maxQueueSize: 3, maxBatchSize: 99);
    }
    expect(q, [2, 3, 4]);
  });

  test('shouldSampleLog keeps ERROR at zero sample rate', () {
    const entry = NativeLogEntry(
      message: 'boom',
      tags: {'level': 'ERROR'},
    );
    expect(shouldSampleLog(entry, 0), isTrue);
  });
}
