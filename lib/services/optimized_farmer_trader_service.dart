import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Optimized service for farmer and trader operations
/// Handles caching, batch operations, and performance optimization for 50K+ users
class OptimizedFarmerTraderService {
  static final OptimizedFarmerTraderService _instance = OptimizedFarmerTraderService._internal();
  factory OptimizedFarmerTraderService() => _instance;
  OptimizedFarmerTraderService._internal();

  // Cache management
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Connection pool for database operations
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Get cached data or fetch from database
  Future<T?> _getCachedData<T>(String key, Future<T> Function() fetchFunction) async {
    final now = DateTime.now();
    
    // Check if cache exists and is not expired
    if (_cache.containsKey(key) && _cacheTimestamps.containsKey(key)) {
      final cacheTime = _cacheTimestamps[key]!;
      if (now.difference(cacheTime) < _cacheExpiry) {
        return _cache[key] as T;
      }
    }

    // Fetch new data
    try {
      final data = await fetchFunction();
      _cache[key] = data;
      _cacheTimestamps[key] = now;
      return data;
    } catch (e) {
      // Return cached data if available, even if expired
      if (_cache.containsKey(key)) {
        return _cache[key] as T;
      }
      rethrow;
    }
  }

  /// Clear cache for specific key or all cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Get optimized crops list with caching
  Future<List<Map<String, dynamic>>> getCrops({int limit = 200}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'crops_$limit',
      () async {
        final snapshot = await _database
            .child('allcrops')
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value;
        if (data is Map) {
          return data.values
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        } else if (data is List) {
          return data
              .where((e) => e != null)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        return [];
      },
    ) ?? [];
  }

  /// Get farmer orders with optimized queries
  Future<List<Map<String, dynamic>>> getFarmerOrders(String userId, {int limit = 100}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'farmer_orders_$userId',
      () async {
        // Try optimized query first
        var snapshot = await _database
            .child('addedcropsbykissan')
            .child(userId)
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();
        
        // If no data with createdAt ordering, try basic query
        if (snapshot.snapshot.value == null) {
          snapshot = await _database
              .child('addedcropsbykissan')
              .child(userId)
              .once();
        }

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> orders = [];

        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          orders.add(order);
        });

        orders.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return orders;
      },
    ) ?? [];
  }

  /// Get trader orders with parallel queries
  Future<List<Map<String, dynamic>>> getTraderOrders(String userId, {int limit = 100}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'trader_orders_$userId',
      () async {
        // Try parallel optimized queries first
        var futures = await Future.wait([
          _database
              .child('requestednewcropbyvyapari')
              .child(userId)
              .orderByChild('createdAt')
              .limitToLast(limit)
              .once(),
          _database
              .child('addedcropsbyvyapari')
              .child(userId)
              .orderByChild('createdAt')
              .limitToLast(limit)
              .once(),
        ]);
        
        // If no data with createdAt ordering, try basic queries
        if (futures[0].snapshot.value == null && futures[1].snapshot.value == null) {
          futures = await Future.wait([
            _database
                .child('requestednewcropbyvyapari')
                .child(userId)
                .once(),
            _database
                .child('addedcropsbyvyapari')
                .child(userId)
                .once(),
          ]);
        }

        List<Map<String, dynamic>> allOrders = [];

        // Process requested crops
        if (futures[0].snapshot.value != null) {
          final requestedData = futures[0].snapshot.value as Map;
          requestedData.forEach((key, value) {
            final order = Map<String, dynamic>.from(value);
            order['id'] = key;
            order['source'] = 'requested';
            allOrders.add(order);
          });
        }

        // Process added crops
        if (futures[1].snapshot.value != null) {
          final addedData = futures[1].snapshot.value as Map;
          addedData.forEach((key, value) {
            final order = Map<String, dynamic>.from(value);
            order['id'] = key;
            order['source'] = 'added';
            allOrders.add(order);
          });
        }

        allOrders.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return allOrders;
      },
    ) ?? [];
  }

  /// Get farmer request history with optimization
  Future<List<Map<String, dynamic>>> getFarmerRequestHistory(String userId, {int limit = 100}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'farmer_history_$userId',
      () async {
        final snapshot = await _database
            .child('requestednewcrop')
            .child(userId)
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> requests = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          requests.add(request);
        });

        requests.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return requests;
      },
    ) ?? [];
  }

  /// Get trader request history with optimization
  Future<List<Map<String, dynamic>>> getTraderRequestHistory(String userId, {int limit = 100}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'trader_history_$userId',
      () async {
        final snapshot = await _database
            .child('requestednewcropbyvyapari')
            .child(userId)
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> requests = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          requests.add(request);
        });

        requests.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return requests;
      },
    ) ?? [];
  }

  /// Get sapling orders with optimization
  Future<List<Map<String, dynamic>>> getSaplingOrders(String userId, {int limit = 50}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'sapling_orders_$userId',
      () async {
        final snapshot = await _database
            .child('saplingorders')
            .child(userId)
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> orders = [];

        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          orders.add(order);
        });

        orders.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return orders;
      },
    ) ?? [];
  }

  /// Get test requests with optimization
  Future<List<Map<String, dynamic>>> getTestRequests(String userId, {int limit = 50}) async {
    return await _getCachedData<List<Map<String, dynamic>>>(
      'test_requests_$userId',
      () async {
        final snapshot = await _database
            .child('testrequests')
            .child(userId)
            .orderByChild('createdAt')
            .limitToLast(limit)
            .once();

        if (snapshot.snapshot.value == null) return [];

        final data = snapshot.snapshot.value as Map;
        List<Map<String, dynamic>> requests = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          requests.add(request);
        });

        requests.sort((a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0));
        return requests;
      },
    ) ?? [];
  }

  /// Batch update operations for better performance
  Future<void> batchUpdateOrders(List<Map<String, dynamic>> updates) async {
    final Map<String, Object?> updateData = {};
    
    for (final update in updates) {
      final path = update['path'] as String;
      final data = update['data'] as Map<String, dynamic>;
      updateData[path] = data;
    }

    if (updateData.isNotEmpty) {
      await _database.update(updateData);
      // Clear related cache
      clearCache();
    }
  }

  /// Get user profile with caching
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    return await _getCachedData<Map<String, dynamic>?>(
      'user_profile_$userId',
      () async {
        final snapshot = await _database.child('users').child(userId).once();
        if (snapshot.snapshot.value != null) {
          return Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        }
        return null;
      },
    );
  }

  /// Calculate order statistics efficiently
  Map<String, dynamic> calculateOrderStatistics(List<Map<String, dynamic>> orders) {
    int totalOrders = orders.length;
    int pendingOrders = 0;
    int confirmedOrders = 0;
    int deliveredOrders = 0;
    double totalAmount = 0.0;

    for (final order in orders) {
      final status = order['status']?.toString().toLowerCase() ?? 'unknown';
      switch (status) {
        case 'pending':
          pendingOrders++;
          break;
        case 'confirmed':
          confirmedOrders++;
          break;
        case 'delivered':
          deliveredOrders++;
          break;
      }

      // Calculate amount based on order type
      final price = (order['pricePerUnit'] ?? order['expectedPrice'] ?? 0).toDouble();
      final quantity = (order['quantity'] ?? 0).toDouble();
      totalAmount += price * quantity;
    }

    return {
      'totalOrders': totalOrders,
      'pendingOrders': pendingOrders,
      'confirmedOrders': confirmedOrders,
      'deliveredOrders': deliveredOrders,
      'totalAmount': totalAmount,
    };
  }

  /// Preload data for better user experience
  Future<void> preloadUserData(String userId, String userType) async {
    final futures = <Future>[];

    // Preload common data
    futures.add(getCrops());
    futures.add(getUserProfile(userId));

    if (userType == 'farmer') {
      futures.add(getFarmerOrders(userId));
      futures.add(getFarmerRequestHistory(userId));
      futures.add(getSaplingOrders(userId));
      futures.add(getTestRequests(userId));
    } else if (userType == 'trader') {
      futures.add(getTraderOrders(userId));
      futures.add(getTraderRequestHistory(userId));
    }

    // Execute all preload operations in parallel
    await Future.wait(futures);
  }

  /// Clean up expired cache entries
  void cleanupCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        expiredKeys.add(key);
      }
    });

    for (final key in expiredKeys) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  /// Get cache statistics for monitoring
  Map<String, dynamic> getCacheStats() {
    return {
      'totalCacheEntries': _cache.length,
      'cacheSize': _cache.toString().length,
      'oldestEntry': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b),
      'newestEntry': _cacheTimestamps.values.isEmpty 
          ? null 
          : _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b),
    };
  }
}