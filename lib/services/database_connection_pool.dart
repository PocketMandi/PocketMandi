import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class DatabaseConnectionPool {
  static final Map<String, StreamSubscription> _activeStreams = {};
  static final Map<String, Timer> _streamTimers = {};
  static const Duration _streamTimeout = Duration(minutes: 10);
  
  /// Get or create a managed stream
  static Stream<DatabaseEvent> getManagedStream(
    String streamId,
    DatabaseReference ref,
  ) {
    // Cancel existing timer for this stream
    _streamTimers[streamId]?.cancel();
    
    // Create new timer to auto-cleanup
    _streamTimers[streamId] = Timer(_streamTimeout, () {
      _cleanupStream(streamId);
    });
    
    return ref.onValue;
  }
  
  /// Cleanup a specific stream
  static void _cleanupStream(String streamId) {
    _activeStreams[streamId]?.cancel();
    _activeStreams.remove(streamId);
    _streamTimers[streamId]?.cancel();
    _streamTimers.remove(streamId);
  }
  
  /// Cleanup all streams
  static void cleanupAllStreams() {
    for (var subscription in _activeStreams.values) {
      subscription.cancel();
    }
    for (var timer in _streamTimers.values) {
      timer.cancel();
    }
    _activeStreams.clear();
    _streamTimers.clear();
  }
  
  /// Extend stream lifetime
  static void extendStreamLifetime(String streamId) {
    _streamTimers[streamId]?.cancel();
    _streamTimers[streamId] = Timer(_streamTimeout, () {
      _cleanupStream(streamId);
    });
  }
}

class QueryOptimizer {
  /// Optimize query for large datasets
  static Query optimizeQuery(
    DatabaseReference ref,
    String orderBy, {
    int? limit,
    dynamic startAt,
    dynamic endAt,
    dynamic equalTo,
  }) {
    Query query = ref;
    
    // Apply ordering
    query = query.orderByChild(orderBy);
    
    // Apply filters
    if (equalTo != null) {
      query = query.equalTo(equalTo);
    }
    
    if (startAt != null) {
      query = query.startAt(startAt);
    }
    
    if (endAt != null) {
      query = query.endAt(endAt);
    }
    
    // Apply limit (default to 100 for performance)
    query = query.limitToLast(limit ?? 100);
    
    return query;
  }
  
  /// Batch process large datasets
  static Future<List<T>> batchProcess<T>(
    List<dynamic> items,
    Future<T> Function(dynamic item) processor, {
    int batchSize = 50,
    Duration delay = const Duration(milliseconds: 100),
  }) async {
    final results = <T>[];
    
    for (int i = 0; i < items.length; i += batchSize) {
      final batch = items.skip(i).take(batchSize).toList();
      final batchResults = await Future.wait(
        batch.map(processor).toList(),
      );
      results.addAll(batchResults);
      
      // Add delay between batches
      if (i + batchSize < items.length) {
        await Future.delayed(delay);
      }
    }
    
    return results;
  }
  
  /// Get optimized user count by role
  static Future<Map<String, int>> getOptimizedUserCounts() async {
    final completer = Completer<Map<String, int>>();
    final counts = {'farmers': 0, 'traders': 0, 'admins': 0, 'total': 0};
    
    // Use single query with efficient counting
    final subscription = FirebaseDatabase.instance
        .ref('users')
        .orderByChild('role')
        .onValue
        .listen((event) {
      if (event.snapshot.value != null) {
        final users = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        for (var userData in users.values) {
          if (userData is Map) {
            counts['total'] = counts['total']! + 1;
            final role = userData['role']?.toString() ?? '';
            
            switch (role) {
              case 'farmer':
                counts['farmers'] = counts['farmers']! + 1;
                break;
              case 'trader':
                counts['traders'] = counts['traders']! + 1;
                break;
              case 'admin':
              case 'superadmin':
                counts['admins'] = counts['admins']! + 1;
                break;
            }
          }
        }
      }
      
      completer.complete(counts);
    });
    
    // Auto-cleanup after getting result
    completer.future.then((_) => subscription.cancel());
    
    return completer.future;
  }
}

class DatabaseIndexManager {
  /// Recommended database rules for optimal performance
  static const String recommendedRules = '''
{
  "rules": {
    "users": {
      ".indexOn": ["role", "createdAt", "kycStatus", "lastActive"],
      "\$userId": {
        ".read": "\$userId === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'",
        ".write": "\$userId === auth.uid || root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    },
    "notifications": {
      "\$userId": {
        ".indexOn": ["createdAt", "read", "type"],
        ".read": "\$userId === auth.uid",
        ".write": "root.child('users').child(auth.uid).child('role').val() === 'admin'"
      }
    },
    "requestednewcrop": {
      ".indexOn": ["createdAt", "status"],
      ".read": "root.child('users').child(auth.uid).child('role').val() === 'admin'",
      ".write": "auth != null"
    },
    "requestednewcropbyvyapari": {
      ".indexOn": ["createdAt", "status"],
      ".read": "root.child('users').child(auth.uid).child('role').val() === 'admin'",
      ".write": "auth != null"
    },
    "addedcropsbykissan": {
      ".indexOn": ["createdAt", "status"],
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "addedcropsbyvyapari": {
      ".indexOn": ["createdAt", "status"],
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "saplingorders": {
      ".indexOn": ["createdAt", "status"],
      ".read": "root.child('users').child(auth.uid).child('role').val() === 'admin'",
      ".write": "auth != null"
    },
    "testrequests": {
      ".indexOn": ["createdAt", "status"],
      ".read": "root.child('users').child(auth.uid).child('role').val() === 'admin'",
      ".write": "auth != null"
    }
  }
}
''';
  
  /// Performance monitoring
  static void logQueryPerformance(String queryName, DateTime startTime) {
    final duration = DateTime.now().difference(startTime);
    print('Query "$queryName" took ${duration.inMilliseconds}ms');
    
    // Log slow queries (>2 seconds)
    if (duration.inSeconds > 2) {
      print('WARNING: Slow query detected - $queryName (${duration.inSeconds}s)');
    }
  }
}