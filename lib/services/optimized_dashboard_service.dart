import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class OptimizedDashboardService {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);
  
  /// Get cached data or fetch from database
  static Future<T?> getCachedData<T>(
    String key,
    Future<T> Function() fetcher,
  ) async {
    final now = DateTime.now();
    final timestamp = _cacheTimestamps[key];
    
    // Return cached data if still valid
    if (timestamp != null && 
        now.difference(timestamp) < _cacheExpiry && 
        _cache.containsKey(key)) {
      return _cache[key] as T;
    }
    
    // Fetch new data
    try {
      final data = await fetcher();
      _cache[key] = data;
      _cacheTimestamps[key] = now;
      return data;
    } catch (e) {
      print('Error fetching data for key $key: $e');
      return null;
    }
  }
  
  /// Get optimized user statistics
  static Future<Map<String, int>> getUserStatistics() async {
    return await getCachedData('user_stats', () async {
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('role')
          .once();
      
      final stats = {
        'total': 0,
        'farmers': 0,
        'traders': 0,
        'admins': 0,
        'pending_kyc': 0,
        'active_today': 0,
      };
      
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final today = DateTime.now();
        final todayStart = DateTime(today.year, today.month, today.day);
        
        for (var userData in users.values) {
          if (userData is Map) {
            stats['total'] = stats['total']! + 1;
            
            final role = userData['role']?.toString() ?? '';
            switch (role) {
              case 'farmer':
                stats['farmers'] = stats['farmers']! + 1;
                break;
              case 'trader':
                stats['traders'] = stats['traders']! + 1;
                break;
              case 'admin':
              case 'superadmin':
                stats['admins'] = stats['admins']! + 1;
                break;
            }
            
            if (userData['kycStatus'] == 'pending') {
              stats['pending_kyc'] = stats['pending_kyc']! + 1;
            }
            
            // Check if user was active today
            final lastActive = userData['lastActive'];
            if (lastActive != null) {
              try {
                final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(lastActive);
                if (lastActiveDate.isAfter(todayStart)) {
                  stats['active_today'] = stats['active_today']! + 1;
                }
              } catch (e) {
                // Handle invalid timestamp
              }
            }
          }
        }
      }
      
      return stats;
    }) ?? {};
  }
  
  /// Get optimized request statistics
  static Future<Map<String, int>> getRequestStatistics() async {
    return await getCachedData('request_stats', () async {
      final stats = {
        'farmer_unlisted': 0,
        'trader_unlisted': 0,
        'farmer_crops': 0,
        'trader_crops': 0,
        'sapling_orders': 0,
        'test_requests': 0,
        'pending_total': 0,
      };
      
      // Use parallel queries for better performance
      final futures = [
        _getCollectionCount('requestednewcrop'),
        _getCollectionCount('requestednewcropbyvyapari'),
        _getCollectionCount('addedcropsbykissan'),
        _getCollectionCount('addedcropsbyvyapari'),
        _getCollectionCount('saplingorders'),
        _getCollectionCount('testrequests'),
      ];
      
      final results = await Future.wait(futures);
      
      stats['farmer_unlisted'] = results[0]['total'] ?? 0;
      stats['trader_unlisted'] = results[1]['total'] ?? 0;
      stats['farmer_crops'] = results[2]['total'] ?? 0;
      stats['trader_crops'] = results[3]['total'] ?? 0;
      stats['sapling_orders'] = results[4]['total'] ?? 0;
      stats['test_requests'] = results[5]['total'] ?? 0;
      
      // Calculate pending total
      stats['pending_total'] = (results[0]['pending'] ?? 0) +
                              (results[1]['pending'] ?? 0) +
                              (results[2]['pending'] ?? 0) +
                              (results[3]['pending'] ?? 0) +
                              (results[4]['pending'] ?? 0) +
                              (results[5]['pending'] ?? 0);
      
      return stats;
    }) ?? {};
  }
  
  /// Get count and pending count for a collection
  static Future<Map<String, int>> _getCollectionCount(String collection) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref(collection)
          .orderByChild('createdAt')
          .limitToLast(1000) // Limit for performance
          .once();
      
      int total = 0;
      int pending = 0;
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        
        for (var userEntries in data.values) {
          if (userEntries is Map) {
            for (var entry in userEntries.values) {
              if (entry is Map) {
                total++;
                if (entry['status'] == 'pending' || entry['status'] == null) {
                  pending++;
                }
              }
            }
          }
        }
      }
      
      return {'total': total, 'pending': pending};
    } catch (e) {
      print('Error getting count for $collection: $e');
      return {'total': 0, 'pending': 0};
    }
  }
  
  /// Get recent activities (optimized)
  static Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 20}) async {
    return await getCachedData('recent_activities', () async {
      final activities = <Map<String, dynamic>>[];
      
      // Get recent activities from multiple collections in parallel
      final futures = [
        _getRecentFromCollection('requestednewcrop', 'Farmer requested new crop', limit ~/ 4),
        _getRecentFromCollection('requestednewcropbyvyapari', 'Trader requested new crop', limit ~/ 4),
        _getRecentFromCollection('saplingorders', 'New sapling order', limit ~/ 4),
        _getRecentFromCollection('testrequests', 'New test request', limit ~/ 4),
      ];
      
      final results = await Future.wait(futures);
      
      // Combine and sort all activities
      for (var result in results) {
        activities.addAll(result);
      }
      
      activities.sort((a, b) => (b['timestamp'] as int).compareTo(a['timestamp'] as int));
      
      return activities.take(limit).toList();
    }) ?? [];
  }
  
  /// Get recent activities from a specific collection
  static Future<List<Map<String, dynamic>>> _getRecentFromCollection(
    String collection,
    String activityType,
    int limit,
  ) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref(collection)
          .orderByChild('createdAt')
          .limitToLast(limit)
          .once();
      
      final activities = <Map<String, dynamic>>[];
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        
        for (var userEntries in data.values) {
          if (userEntries is Map) {
            for (var entry in userEntries.values) {
              if (entry is Map && entry['createdAt'] != null) {
                activities.add({
                  'type': activityType,
                  'timestamp': entry['createdAt'],
                  'userName': entry['userName'] ?? 'Unknown',
                  'status': entry['status'] ?? 'pending',
                  'details': entry['cropName'] ?? entry['cropType'] ?? 'N/A',
                });
              }
            }
          }
        }
      }
      
      return activities;
    } catch (e) {
      print('Error getting recent activities from $collection: $e');
      return [];
    }
  }
  
  /// Clear cache (call when needed)
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }
  
  /// Clear specific cache entry
  static void clearCacheEntry(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
  
  /// Get paginated users
  static Future<List<Map<String, dynamic>>> getPaginatedUsers({
    String? role,
    String? kycStatus,
    String? searchQuery,
    int limit = 50,
    String? startAfter,
  }) async {
    try {
      Query query = FirebaseDatabase.instance.ref('users');
      
      // Apply role filter if specified
      if (role != null && role != 'all') {
        query = query.orderByChild('role').equalTo(role);
      } else {
        query = query.orderByChild('createdAt');
      }
      
      // Apply limit
      query = query.limitToFirst(limit);
      
      final snapshot = await query.once();
      final users = <Map<String, dynamic>>[];
      
      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        
        for (var entry in data.entries) {
          final userData = Map<String, dynamic>.from(entry.value as Map);
          userData['id'] = entry.key;
          
          // Apply additional filters
          if (kycStatus != null && kycStatus != 'all' && userData['kycStatus'] != kycStatus) {
            continue;
          }
          
          if (searchQuery != null && searchQuery.isNotEmpty) {
            final name = (userData['name'] ?? '').toString().toLowerCase();
            final phone = (userData['phone'] ?? '').toString().toLowerCase();
            if (!name.contains(searchQuery.toLowerCase()) && 
                !phone.contains(searchQuery.toLowerCase())) {
              continue;
            }
          }
          
          users.add(userData);
        }
      }
      
      return users;
    } catch (e) {
      print('Error getting paginated users: $e');
      return [];
    }
  }
}