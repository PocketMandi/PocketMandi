import 'package:flutter/foundation.dart';
import 'dart:developer' as developer;

class PerformanceMonitor {
  // Monitor database operations
  static Future<T> monitorDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await operation();
      stopwatch.stop();
      
      if (kDebugMode) {
        print('✅ $operationName completed in ${stopwatch.elapsedMilliseconds}ms');
        developer.log(
          'Database Operation: $operationName',
          name: 'PerformanceMonitor',
          time: DateTime.now(),
          sequenceNumber: stopwatch.elapsedMilliseconds,
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        print('❌ $operationName failed after ${stopwatch.elapsedMilliseconds}ms: $e');
        developer.log(
          'Database Operation Failed: $operationName',
          name: 'PerformanceMonitor',
          error: e,
          time: DateTime.now(),
        );
      }
      
      rethrow;
    }
  }
  
  // Monitor network requests
  static Future<T> monitorNetworkRequest<T>(
    String url,
    Future<T> Function() request,
  ) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final result = await request();
      stopwatch.stop();
      
      if (kDebugMode) {
        print('🌐 Network request to $url completed in ${stopwatch.elapsedMilliseconds}ms');
        developer.log(
          'Network Request: $url',
          name: 'PerformanceMonitor',
          time: DateTime.now(),
          sequenceNumber: stopwatch.elapsedMilliseconds,
        );
      }
      
      return result;
    } catch (e) {
      stopwatch.stop();
      
      if (kDebugMode) {
        print('❌ Network request to $url failed after ${stopwatch.elapsedMilliseconds}ms: $e');
        developer.log(
          'Network Request Failed: $url',
          name: 'PerformanceMonitor',
          error: e,
          time: DateTime.now(),
        );
      }
      
      rethrow;
    }
  }
  
  // Monitor memory usage
  static void logMemoryUsage(String context) {
    if (kDebugMode) {
      print('📊 Memory check at $context');
      developer.log(
        'Memory Usage Check: $context',
        name: 'PerformanceMonitor',
        time: DateTime.now(),
      );
    }
  }
  
  // Log performance metrics
  static void logMetric(String name, int value, {String? unit}) {
    if (kDebugMode) {
      print('📈 Metric: $name = $value${unit ?? ''}');
      developer.log(
        'Performance Metric: $name',
        name: 'PerformanceMonitor',
        time: DateTime.now(),
        sequenceNumber: value,
      );
    }
  }
  
  // Start a custom timer
  static Stopwatch startTimer(String operationName) {
    if (kDebugMode) {
      print('⏱️ Starting timer for: $operationName');
    }
    return Stopwatch()..start();
  }
  
  // Stop a custom timer
  static void stopTimer(Stopwatch stopwatch, String operationName) {
    stopwatch.stop();
    if (kDebugMode) {
      print('⏹️ $operationName completed in ${stopwatch.elapsedMilliseconds}ms');
      developer.log(
        'Custom Timer: $operationName',
        name: 'PerformanceMonitor',
        time: DateTime.now(),
        sequenceNumber: stopwatch.elapsedMilliseconds,
      );
    }
  }
}