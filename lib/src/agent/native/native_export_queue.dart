import 'dart:math';

import 'native_log_entry.dart';

/// Bounded in-memory export queue (drop oldest when over [maxQueueSize]).
void enqueueCapped<T>(
  List<T> queue,
  T item, {
  required int maxQueueSize,
  required int maxBatchSize,
  void Function()? onReachBatchSize,
}) {
  if (maxQueueSize > 0 && queue.length >= maxQueueSize) {
    queue.removeAt(0);
  }
  queue.add(item);
  if (onReachBatchSize != null && queue.length >= maxBatchSize) {
    onReachBatchSize();
  }
}

final _logSampleRandom = Random();

/// Whether a biz log should be exported ([logSampleRate] in `(0,1)` skips non-ERROR).
bool shouldSampleLog(NativeLogEntry entry, double logSampleRate) {
  final level = (entry.tags['level'] ?? '').toUpperCase();
  if (level == 'ERROR') return true;
  if (logSampleRate >= 1.0) return true;
  if (logSampleRate <= 0.0) return false;
  return _logSampleRandom.nextDouble() < logSampleRate;
}
