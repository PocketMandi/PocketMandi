import 'dart:developer' as developer;

class PerformanceUtils {
  static final Map<String, DateTime> _timers = {};
  
  /// Start timing an operation
  static void startTimer(String operation) {
    _timers[operation] = DateTime.now();
    developer.log('Started: $operation', name: 'Performance');
  }
  
  /// End timing an operation and log the duration
  static void endTimer(String operation) {
    final startTime = _timers[operation];
    if (startTime != null) {
      final duration = DateTime.now().difference(startTime);
      developer.log('Completed: $operation in ${duration.inMilliseconds}ms', name: 'Performance');
      _timers.remove(operation);
    }
  }
  
  /// Log memory usage (for debugging)
  static void logMemoryUsage(String context) {
    developer.log('Memory check: $context', name: 'Memory');
  }
  
  /// Batch operation helper
  static Future<void> processBatch<T>(
    List<T> items,
    Future<void> Function(T item) processor, {
    int batchSize = 50,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      final futures = batch.map(processor).toList();
      await Future.wait(futures);
      
      // Add delay between batches to prevent overwhelming the system
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }
  }
}