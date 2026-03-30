import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:poket_mandi/screens/common/notifications_list_screen.dart';
import 'package:poket_mandi/screens/kisan/my_order_screen.dart';
import 'package:poket_mandi/screens/kisan/kisan_dashboard_screen.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static BuildContext? _context;
  static final Set<String> _shownNotifications =
      {}; // Track shown notifications

  static void setContext(BuildContext context) {
    _context = context;
  }

  static Future<void> initialize() async {
    // Request permission for iOS and Android 13+
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print('Notification tapped: ${response.payload}');
        _handleNotificationTap(response.payload, response.id);
      },
    );

    // Request Android 13+ notification permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Get FCM token and save to Firebase
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveFCMToken(token);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle background messages
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!');
      _handleFCMNotificationTap(message);
    });

    // DON'T listen to Firebase database for notifications
    // The Cloud Function will send FCM notifications directly
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        print('DEBUG: Saving FCM token for user: $userId');

        // CRITICAL: Remove this token from ALL other users first
        await _removeTokenFromOtherUsers(token, userId);

        // Now save token to current user
        await FirebaseDatabase.instance
            .ref('users/$userId/fcmToken')
            .set(token);
        print('FCM Token saved: $token');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  // Remove FCM token from all other users (prevent token duplication)
  static Future<void> _removeTokenFromOtherUsers(
    String token,
    String currentUserId,
  ) async {
    try {
      print('DEBUG: Checking for duplicate tokens...');
      final snapshot = await FirebaseDatabase.instance.ref('users').once();

      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        for (var entry in users.entries) {
          final otherUserId = entry.key;
          final userData = entry.value as Map;
          final otherToken = userData['fcmToken'];

          // If another user has the same token, remove it
          if (otherToken == token && otherUserId != currentUserId) {
            print('DEBUG: Removing duplicate token from user: $otherUserId');
            await FirebaseDatabase.instance
                .ref('users/$otherUserId/fcmToken')
                .remove();
          }
        }
      }
    } catch (e) {
      print('Error removing duplicate tokens: $e');
    }
  }

  // Get current FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Extract type from message data
      final type = message.data['type'] ?? 'notification';

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        notificationDetails: notificationDetails,
        payload: type,
      );
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      print('DEBUG: sendNotificationToUser called');
      print('DEBUG: Target userId = $userId');
      print('DEBUG: Notification title = $title');
      print('DEBUG: Notification body = $body');
      print('DEBUG: Notification type = $type');

      // Get current logged-in user FIRST before saving to database
      final prefs = await SharedPreferences.getInstance();
      final currentUserId = prefs.getString('user_id');
      final currentUserRole = prefs.getString('user_role');

      print('DEBUG: Current logged-in userId = $currentUserId');
      print('DEBUG: Current logged-in userRole = $currentUserRole');
      print('DEBUG: Does userId match? ${currentUserId == userId}');

      // Verify target user exists and get their role
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/$userId')
          .once();

      if (userSnapshot.snapshot.value == null) {
        print('ERROR: Target user $userId does not exist!');
        return;
      }

      final targetUserData = userSnapshot.snapshot.value as Map;
      final targetUserRole = targetUserData['role'];
      print('DEBUG: Target user role = $targetUserRole');

      // Save notification to database for the TARGET user
      await FirebaseDatabase.instance.ref('notifications/$userId').push().set({
        'title': title,
        'body': body,
        'type': type ?? 'notification',
        'data': data,
        'read': false,
        'createdAt': ServerValue.timestamp,
      });

      print('DEBUG: Notification saved to database for userId: $userId');

      // ONLY show local notification if:
      // 1. The target userId matches the current logged-in userId
      // 2. AND the roles match (extra safety check)
      if (currentUserId == userId && currentUserRole == targetUserRole) {
        print('DEBUG: Showing local notification - user IDs and roles match');
        const androidDetails = AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription:
              'This channel is used for important notifications.',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        );

        const iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

        const notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _localNotifications.show(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: title,
          body: body,
          notificationDetails: notificationDetails,
          payload: type ?? 'notification',
        );
      } else {
        print('DEBUG: NOT showing local notification');
        print(
          'DEBUG: Reason: userId mismatch ($currentUserId != $userId) or role mismatch ($currentUserRole != $targetUserRole)',
        );
      }

      print('Notification saved for user: $userId');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification to all admins
  static Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Get all users
      final snapshot = await FirebaseDatabase.instance.ref('users').once();

      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);

        // Filter and send to all admins and superadmins
        for (var entry in users.entries) {
          final userId = entry.key;
          final userData = Map<String, dynamic>.from(entry.value as Map);
          final role = userData['role']?.toString() ?? '';

          // Send to both admin and superadmin roles
          if (role == 'admin' || role == 'superadmin') {
            print('Sending notification to $role: $userId');
            await sendNotificationToUser(
              userId: userId,
              title: title,
              body: body,
              type: type,
              data: data,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending notification to admins: $e');
    }
  }

  // Send notification to all farmers
  static Future<void> sendNotificationToFarmers({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users').once();
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        for (var entry in users.entries) {
          final userId = entry.key;
          final userData = Map<String, dynamic>.from(entry.value as Map);
          final role = userData['role']?.toString() ?? '';
          if (role == 'farmer') {
            await sendNotificationToUser(
              userId: userId,
              title: title,
              body: body,
              type: type,
              data: data,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending notification to farmers: $e');
    }
  }

  // Send notification to all traders
  static Future<void> sendNotificationToTraders({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users').once();
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        for (var entry in users.entries) {
          final userId = entry.key;
          final userData = Map<String, dynamic>.from(entry.value as Map);
          final role = userData['role']?.toString() ?? '';
          if (role == 'trader') {
            await sendNotificationToUser(
              userId: userId,
              title: title,
              body: body,
              type: type,
              data: data,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending notification to traders: $e');
    }
  }

  // Send notification to all users (farmers and traders)
  static Future<void> sendNotificationToAllUsers({
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users').once();
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        for (var entry in users.entries) {
          final userId = entry.key;
          final userData = Map<String, dynamic>.from(entry.value as Map);
          final role = userData['role']?.toString() ?? '';
          if (role == 'farmer' || role == 'trader') {
            await sendNotificationToUser(
              userId: userId,
              title: title,
              body: body,
              type: type,
              data: data,
            );
          }
        }
      }
    } catch (e) {
      print('Error sending notification to all users: $e');
    }
  }

  // Get all users for selection
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('users').once();
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        List<Map<String, dynamic>> userList = [];
        for (var entry in users.entries) {
          final userId = entry.key;
          final userData = Map<String, dynamic>.from(entry.value as Map);
          final role = userData['role']?.toString() ?? '';
          if (role == 'farmer' || role == 'trader') {
            userList.add({
              'id': userId,
              'name': userData['name'] ?? 'Unknown',
              'role': role,
              'phone': userData['phone'] ?? '',
            });
          }
        }
        return userList;
      }
      return [];
    } catch (e) {
      print('Error getting all users: $e');
      return [];
    }
  }

  // Handle notification tap
  static void _handleNotificationTap(
    String? payload,
    int? notificationId,
  ) async {
    print('DEBUG: _handleNotificationTap called');
    print('DEBUG: payload = $payload');
    print('DEBUG: payload type = ${payload.runtimeType}');

    if (payload == null || _context == null) {
      print('DEBUG: payload is null or context is null');
      return;
    }

    try {
      // Handle broadcast notifications - navigate to notifications list
      if (payload == 'broadcast') {
        print('DEBUG: Navigating to notifications list for broadcast notification');
        Navigator.of(_context!).push(
          MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
        );
        return;
      }

      // Handle crop request status updates - navigate to History screen
      if (payload == 'crop_request_status') {
        print('DEBUG: Navigating to History screen for crop request status');

        // Get user role to determine which dashboard to navigate to
        final prefs = await SharedPreferences.getInstance();
        final userRole = prefs.getString('user_role');

        print('DEBUG: User role = $userRole');

        if (userRole == 'farmer') {
          // Navigate to Kisan Dashboard with History tab selected (index 2)
          Navigator.of(_context!).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const KisanDashboardScreenWithTab(initialTab: 2),
            ),
          );
        } else if (userRole == 'trader') {
          // Navigate to Vyapari Dashboard with History tab selected (index 2)
          Navigator.of(_context!).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const VyapariDashboardScreen(initialTab: 2),
            ),
          );
        } else {
          print('DEBUG: Unknown role, navigating to appropriate orders screen');
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const KisanDashboardScreenWithTab(initialTab: 2)),
          );
        }
        return;
      }

      print(
        'DEBUG: payload did not match crop_request_status, checking other cases',
      );

      // For other notification types, navigate to appropriate orders screen based on role
      if (payload == 'sapling_order_status' || payload == 'test_request_status' || payload == 'crop_order_status') {
        print('DEBUG: Navigating to Orders screen for $payload');
        
        final prefs = await SharedPreferences.getInstance();
        final userRole = prefs.getString('user_role');
        
        if (userRole == 'farmer') {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const KisanDashboardScreenWithTab(initialTab: 1)),
          );
        } else if (userRole == 'trader') {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => VyapariDashboardScreen(initialTab: 1)),
          );
        } else {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
        }
        return;
      }

      // Admin notifications
      int tabIndex = 0;

      switch (payload) {
        case 'crop_request':
          tabIndex = 0;
          break;
        case 'crop_order':
          tabIndex = 2;
          break;
        case 'sapling_order':
          tabIndex = 4;
          break;
        case 'test_request':
          tabIndex = 5;
          break;
        case 'new_user':
          return;
      }

      print(
        'DEBUG: Navigating to RequestsManagementScreenWithTab with tabIndex: $tabIndex',
      );
      Navigator.of(_context!).push(
        MaterialPageRoute(
          builder: (_) => RequestsManagementScreenWithTab(initialTab: tabIndex),
        ),
      );
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  // Handle FCM notification tap
  static void _handleFCMNotificationTap(RemoteMessage message) async {
    if (_context == null) return;

    try {
      final type = message.data['type'];
      if (type == null) return;

      print('DEBUG: FCM notification type = $type');

      // Handle broadcast notifications - navigate to notifications list
      if (type == 'broadcast') {
        print('DEBUG: FCM - Navigating to notifications list for broadcast notification');
        Navigator.of(_context!).push(
          MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
        );
        return;
      }

      // Handle crop request status updates - navigate to History screen
      if (type == 'crop_request_status') {
        print(
          'DEBUG: FCM - Navigating to History screen for crop request status',
        );

        // Get user role to determine which dashboard to navigate to
        final prefs = await SharedPreferences.getInstance();
        final userRole = prefs.getString('user_role');

        print('DEBUG: FCM - User role = $userRole');

        if (userRole == 'farmer') {
          // Navigate to Kisan Dashboard with History tab selected (index 2)
          Navigator.of(_context!).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const KisanDashboardScreenWithTab(initialTab: 2),
            ),
          );
        } else if (userRole == 'trader') {
          // Navigate to Vyapari Dashboard with History tab selected (index 2)
          Navigator.of(_context!).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const VyapariDashboardScreen(initialTab: 2),
            ),
          );
        } else {
          print('DEBUG: FCM - Unknown role, navigating to appropriate orders screen');
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const KisanDashboardScreenWithTab(initialTab: 2)),
          );
        }
        return;
      }

      // For other notification types, navigate to appropriate orders screen based on role
      if (type == 'sapling_order_status' || type == 'test_request_status' || type == 'crop_order_status') {
        print('DEBUG: FCM - Navigating to Orders screen for $type');
        
        final prefs = await SharedPreferences.getInstance();
        final userRole = prefs.getString('user_role');
        
        if (userRole == 'farmer') {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const KisanDashboardScreenWithTab(initialTab: 1)),
          );
        } else if (userRole == 'trader') {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => VyapariDashboardScreen(initialTab: 1)),
          );
        } else {
          Navigator.of(_context!).push(
            MaterialPageRoute(builder: (_) => const MyOrdersScreen()),
          );
        }
        return;
      }

      // Admin notifications
      int tabIndex = 0;

      switch (type) {
        case 'crop_request':
          tabIndex = 0;
          break;
        case 'crop_order':
          tabIndex = 2;
          break;
        case 'sapling_order':
          tabIndex = 4;
          break;
        case 'test_request':
          tabIndex = 5;
          break;
        case 'new_user':
          return;
      }

      print(
        'DEBUG: FCM - Navigating to RequestsManagementScreenWithTab with tabIndex: $tabIndex',
      );
      Navigator.of(_context!).push(
        MaterialPageRoute(
          builder: (_) => RequestsManagementScreenWithTab(initialTab: tabIndex),
        ),
      );
    } catch (e) {
      print('Error handling FCM notification tap: $e');
    }
  }

  // Check if user has notifications enabled
  static Future<bool> areNotificationsEnabled(String userId) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId/notificationSettings/enabled')
          .once();

      if (snapshot.snapshot.value != null) {
        return snapshot.snapshot.value as bool;
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  // Check if specific notification type is enabled
  static Future<bool> isNotificationTypeEnabled(
    String userId,
    String type,
  ) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId/notificationSettings/$type')
          .once();

      if (snapshot.snapshot.value != null) {
        return snapshot.snapshot.value as bool;
      }
      return true;
    } catch (e) {
      return true;
    }
  }
}

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}
