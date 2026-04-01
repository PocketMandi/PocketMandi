import 'dart:async';
import 'package:firebase_database/firebase_database.dart';

class UISafeDatabaseService {
  static final UISafeDatabaseService _instance =
      UISafeDatabaseService._internal();
  factory UISafeDatabaseService() => _instance;
  UISafeDatabaseService._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTime = {};
  static const Duration _cacheExpiry = Duration(minutes: 2);
  static const int _maxConcurrentQueries = 50;
  int _currentQueries = 0;

  // Non-blocking query with caching
  Future<T?> safeQuery<T>(
    String path,
    T Function(dynamic) parser, {
    bool useCache = true,
  }) async {
    // Check cache first
    if (useCache && _cache.containsKey(path)) {
      final cacheTime = _cacheTime[path];
      if (cacheTime != null &&
          DateTime.now().difference(cacheTime) < _cacheExpiry) {
        return parser(_cache[path]);
      }
    }

    // Limit concurrent queries
    if (_currentQueries >= _maxConcurrentQueries) {
      await Future.delayed(const Duration(milliseconds: 100));
      return safeQuery(path, parser, useCache: useCache);
    }

    _currentQueries++;

    try {
      final ref = FirebaseDatabase.instance.ref(path);
      final snapshot = await ref.get().timeout(const Duration(seconds: 5));

      if (snapshot.value != null) {
        final data = snapshot.value;

        if (useCache) {
          _cache[path] = data;
          _cacheTime[path] = DateTime.now();
        }

        return parser(data);
      }
      return null;
    } catch (e) {
      print('Query failed for $path: $e');
      return null;
    } finally {
      _currentQueries--;
    }
  }

  // Batch queries with UI safety
  Future<List<T?>> safeBatchQuery<T>(
    List<String> paths,
    T Function(dynamic) parser,
  ) async {
    final results = <T?>[];

    // Process in small batches to keep UI responsive
    for (int i = 0; i < paths.length; i += 3) {
      final batch = paths.skip(i).take(3).toList();
      final batchResults = await Future.wait(
        batch.map((path) => safeQuery(path, parser)),
      );
      results.addAll(batchResults);

      // Yield to UI thread
      if (i + 3 < paths.length) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }

    return results;
  }

  void clearCache() {
    _cache.clear();
    _cacheTime.clear();
  }

  void dispose() {
    clearCache();
    _currentQueries = 0;
  }
}
