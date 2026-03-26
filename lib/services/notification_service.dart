import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
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
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
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
      },
    );

    // Request Android 13+ notification permission
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Create notification channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
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
    });
  }

  static Future<void> _saveFCMToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        await FirebaseDatabase.instance
            .ref('users/$userId/fcmToken')
            .set(token);
        print('FCM Token saved: $token');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
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

      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        notificationDetails: notificationDetails,
        payload: message.data.toString(),
      );
    }
  }

  // Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Save notification to database
      await FirebaseDatabase.instance
          .ref('notifications/$userId')
          .push()
          .set({
        'title': title,
        'body': body,
        'data': data,
        'read': false,
        'createdAt': ServerValue.timestamp,
      });
      
      // Show local notification immediately
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

      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: data?.toString(),
      );
      
      print('Notification sent to user: $userId');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  // Send notification to all admins
  static Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('users')
          .orderByChild('role')
          .equalTo('admin')
          .once();
      
      if (snapshot.snapshot.value != null) {
        final users = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        
        for (var entry in users.entries) {
          final userId = entry.key;
          await sendNotificationToUser(
            userId: userId,
            title: title,
            body: body,
            data: data,
          );
        }
      }
    } catch (e) {
      print('Error sending notification to admins: $e');
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
  static Future<bool> isNotificationTypeEnabled(String userId, String type) async {
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
