import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Performance utilities for farmer and trader operations
/// Provides monitoring, optimization, and batch processing for 50K+ users
class FarmerTraderPerformanceUtils {
  static final FarmerTraderPerformanceUtils _instance =
      FarmerTraderPerformanceUtils._internal();
  factory FarmerTraderPerformanceUtils() => _instance;
  FarmerTraderPerformanceUtils._internal();

  // Performance monitoring
  final Map<String, List<int>> _operationTimes = {};
  final Map<String, int> _operationCounts = {};
  final List<String> _slowOperations = [];

  /// Monitor operation performance
  Future<T> monitorOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    try {
      final result = await operation();
      stopwatch.stop();

      final duration = stopwatch.elapsedMilliseconds;
      _recordOperationTime(operationName, duration);

      // Log slow operations (>2 seconds)
      if (duration > 2000) {
        _slowOperations.add('$operationName: ${duration}ms');
        print('⚠️ Slow operation detected: $operationName took ${duration}ms');
      }

      return result;
    } catch (e) {
      stopwatch.stop();
      print('❌ Operation failed: $operationName - $e');
      rethrow;
    }
  }

  void _recordOperationTime(String operationName, int duration) {
    if (!_operationTimes.containsKey(operationName)) {
      _operationTimes[operationName] = [];
    }
    _operationTimes[operationName]!.add(duration);

    // Keep only last 100 measurements to prevent memory issues
    if (_operationTimes[operationName]!.length > 100) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  /// Get performance statistics
  Map<String, dynamic> getPerformanceStats() {
    final stats = <String, dynamic>{};

    _operationTimes.forEach((operation, times) {
      if (times.isNotEmpty) {
        final avgTime = times.reduce((a, b) => a + b) / times.length;
        final maxTime = times.reduce(max);
        final minTime = times.reduce(min);

        stats[operation] = {
          'count': _operationCounts[operation] ?? 0,
          'avgTime': avgTime.round(),
          'maxTime': maxTime,
          'minTime': minTime,
          'totalCalls': times.length,
        };
      }
    });

    return {
      'operations': stats,
      'slowOperations': _slowOperations.take(10).toList(),
      'totalOperations': _operationCounts.values.fold(0, (a, b) => a + b),
    };
  }

  /// Batch process operations for better performance
  Future<List<T>> batchProcess<T>(
    List<dynamic> items,
    Future<T> Function(dynamic item) processor, {
    int batchSize = 10,
    Duration delay = const Duration(milliseconds: 50),
  }) async {
    final results = <T>[];

    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map((item) => processor(item)),
      );

      results.addAll(batchResults);

      // Add delay between batches to prevent overwhelming the system
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }

    return results;
  }

  /// Optimize list operations for large datasets
  List<T> optimizedFilter<T>(
    List<T> items,
    bool Function(T item) predicate, {
    int? limit,
  }) {
    final results = <T>[];
    int count = 0;

    for (final item in items) {
      if (predicate(item)) {
        results.add(item);
        count++;

        if (limit != null && count >= limit) {
          break;
        }
      }
    }

    return results;
  }

  /// Optimize sorting for large datasets
  List<T> optimizedSort<T>(
    List<T> items,
    int Function(T a, T b) compare, {
    int? limit,
  }) {
    // Use partial sort if limit is specified and less than half the list
    if (limit != null && limit < items.length / 2) {
      return _partialSort(items, compare, limit);
    }

    // Use regular sort for smaller lists or when no limit
    final sorted = List<T>.from(items)..sort(compare);
    return limit != null ? sorted.take(limit).toList() : sorted;
  }

  List<T> _partialSort<T>(
    List<T> items,
    int Function(T a, T b) compare,
    int limit,
  ) {
    if (items.length <= limit) {
      return List<T>.from(items)..sort(compare);
    }

    final result = <T>[];
    final remaining = List<T>.from(items);

    for (int i = 0; i < limit && remaining.isNotEmpty; i++) {
      int bestIndex = 0;
      for (int j = 1; j < remaining.length; j++) {
        if (compare(remaining[j], remaining[bestIndex]) < 0) {
          bestIndex = j;
        }
      }
      result.add(remaining.removeAt(bestIndex));
    }

    return result;
  }

  /// Memory-efficient pagination
  List<T> paginateList<T>(List<T> items, int page, int pageSize) {
    final startIndex = page * pageSize;
    if (startIndex >= items.length) return [];

    final endIndex = min(startIndex + pageSize, items.length);
    return items.sublist(startIndex, endIndex);
  }

  /// Debounce function calls to reduce API load
  Timer? _debounceTimer;
  void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls to limit frequency
  DateTime? _lastThrottleTime;
  bool throttle({Duration interval = const Duration(milliseconds: 500)}) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= interval) {
      _lastThrottleTime = now;
      return true;
    }
    return false;
  }

  /// Calculate order statistics efficiently
  Map<String, dynamic> calculateOrderStats(List<Map<String, dynamic>> orders) {
    if (orders.isEmpty) {
      return {
        'total': 0,
        'pending': 0,
        'confirmed': 0,
        'delivered': 0,
        'rejected': 0,
        'totalAmount': 0.0,
        'avgAmount': 0.0,
      };
    }

    int pending = 0, confirmed = 0, delivered = 0, rejected = 0;
    double totalAmount = 0.0;

    for (final order in orders) {
      final status = order['status']?.toString().toLowerCase() ?? 'unknown';
      switch (status) {
        case 'pending':
          pending++;
          break;
        case 'confirmed':
          confirmed++;
          break;
        case 'delivered':
          delivered++;
          break;
        case 'rejected':
          rejected++;
          break;
      }

      final price = (order['pricePerUnit'] ?? order['expectedPrice'] ?? 0)
          .toDouble();
      final quantity = (order['quantity'] ?? 0).toDouble();
      totalAmount += price * quantity;
    }

    return {
      'total': orders.length,
      'pending': pending,
      'confirmed': confirmed,
      'delivered': delivered,
      'rejected': rejected,
      'totalAmount': totalAmount,
      'avgAmount': totalAmount / orders.length,
    };
  }

  /// Optimize image loading for crop cards
  String optimizeImageUrl(String imageUrl, {int? width, int? height}) {
    if (!imageUrl.startsWith('http')) return imageUrl;

    // Add image optimization parameters if supported
    final uri = Uri.parse(imageUrl);
    final params = Map<String, String>.from(uri.queryParameters);

    if (width != null) params['w'] = width.toString();
    if (height != null) params['h'] = height.toString();
    params['q'] = '80'; // Quality optimization

    return uri.replace(queryParameters: params).toString();
  }

  /// Memory usage monitoring
  Map<String, dynamic> getMemoryStats() {
    return {
      'operationTimesSize': _operationTimes.length,
      'operationCountsSize': _operationCounts.length,
      'slowOperationsSize': _slowOperations.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Clear performance data to free memory
  void clearPerformanceData() {
    _operationTimes.clear();
    _operationCounts.clear();
    _slowOperations.clear();
    _debounceTimer?.cancel();
    _lastThrottleTime = null;
  }

  /// Generate performance report
  String generatePerformanceReport() {
    final stats = getPerformanceStats();
    final memoryStats = getMemoryStats();

    final buffer = StringBuffer();
    buffer.writeln('🚀 Farmer/Trader Performance Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('');

    buffer.writeln('📊 Operation Statistics:');
    final operations = stats['operations'] as Map<String, dynamic>;
    operations.forEach((operation, data) {
      buffer.writeln('  $operation:');
      buffer.writeln('    Calls: ${data['count']}');
      buffer.writeln('    Avg Time: ${data['avgTime']}ms');
      buffer.writeln('    Max Time: ${data['maxTime']}ms');
      buffer.writeln('    Min Time: ${data['minTime']}ms');
    });

    buffer.writeln('');
    buffer.writeln('⚠️ Slow Operations:');
    final slowOps = stats['slowOperations'] as List<String>;
    if (slowOps.isEmpty) {
      buffer.writeln('  None detected ✅');
    } else {
      slowOps.forEach((op) => buffer.writeln('  $op'));
    }

    buffer.writeln('');
    buffer.writeln('💾 Memory Usage:');
    memoryStats.forEach((key, value) {
      buffer.writeln('  $key: $value');
    });

    return buffer.toString();
  }

  /// Validate data integrity for large datasets
  Map<String, dynamic> validateDataIntegrity(List<Map<String, dynamic>> data) {
    int validRecords = 0;
    int invalidRecords = 0;
    final errors = <String>[];

    for (int i = 0; i < data.length; i++) {
      final record = data[i];

      // Check required fields
      if (record['id'] == null || record['id'].toString().isEmpty) {
        errors.add('Record $i: Missing ID');
        invalidRecords++;
        continue;
      }

      if (record['createdAt'] == null) {
        errors.add('Record $i: Missing createdAt');
        invalidRecords++;
        continue;
      }

      validRecords++;
    }

    return {
      'totalRecords': data.length,
      'validRecords': validRecords,
      'invalidRecords': invalidRecords,
      'errors': errors
          .take(10)
          .toList(), // Limit errors to prevent memory issues
      'integrityScore': data.isEmpty ? 1.0 : validRecords / data.length,
    };
  }
}

/// Extension methods for better performance
extension ListOptimization<T> on List<T> {
  /// Chunked processing for large lists
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, min(i + size, length)));
    }
    return chunks;
  }

  /// Safe sublist that handles edge cases
  List<T> safeSublist(int start, [int? end]) {
    if (isEmpty) return [];
    final safeStart = max(0, min(start, length));
    final safeEnd = end == null ? length : max(safeStart, min(end, length));
    return sublist(safeStart, safeEnd);
  }
}
