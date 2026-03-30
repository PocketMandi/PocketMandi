import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserNotificationsListScreen extends StatefulWidget {
  const UserNotificationsListScreen({Key? key}) : super(key: key);

  @override
  State<UserNotificationsListScreen> createState() => _UserNotificationsListScreenState();
}

class _UserNotificationsListScreenState extends State<UserNotificationsListScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? userRole;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      userRole = prefs.getString('user_role');

      if (userId == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref('notifications/$userId')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Map<String, dynamic>> loadedNotifications = [];

        data.forEach((key, value) {
          final notification = Map<String, dynamic>.from(value as Map);
          notification['id'] = key;
          loadedNotifications.add(notification);
        });

        loadedNotifications.sort((a, b) {
          final aTime = a['createdAt'] ?? 0;
          final bTime = b['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        setState(() {
          notifications = loadedNotifications;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      
      if (userId != null) {
        await FirebaseDatabase.instance
            .ref('notifications/$userId/$notificationId')
            .update({'read': true});
        
        // Update local state
        setState(() {
          final index = notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            notifications[index]['read'] = true;
          }
        });
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    // Mark as read
    _markAsRead(notification['id']);
    
    // Show notification details in a dialog
    _showNotificationDetails(notification);
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final createdAt = notification['createdAt'];
    final timeAgo = _getTimeAgo(createdAt);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color(0xFF104f22).withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF104f22).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications,
                      color: Color(0xFF104f22),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E2E2E),
                          ),
                        ),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2E2E2E),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104f22),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF104f22),
              const Color(0xFF104f22).withOpacity(0.8),
              Colors.white,
            ],
            stops: const [0.0, 0.15, 0.15],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Stay updated with latest activities',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Notifications List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF104f22),
                          ),
                        )
                      : notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_off_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No notifications yet',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'You\'ll see notifications here when you get them',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              color: const Color(0xFF104f22),
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notifications[index];
                                  return _buildNotificationCard(notification);
                                },
                              ),
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['read'] == true;
    final title = notification['title'] ?? 'Notification';
    final body = notification['body'] ?? '';
    final createdAt = notification['createdAt'];
    final timeAgo = _getTimeAgo(createdAt);
    final data = notification['data'] as Map<dynamic, dynamic>?;
    final type = data?['type'];

    IconData icon;
    Color iconColor;
    Color bgColor;

    switch (type) {
      case 'order_status':
        icon = Icons.shopping_cart;
        iconColor = Colors.blue;
        bgColor = Colors.blue.shade50;
        break;
      case 'crop_request':
        icon = Icons.grass;
        iconColor = Colors.green;
        bgColor = Colors.green.shade50;
        break;
      case 'price_update':
        icon = Icons.trending_up;
        iconColor = Colors.orange;
        bgColor = Colors.orange.shade50;
        break;
      case 'system':
        icon = Icons.info;
        iconColor = Colors.purple;
        bgColor = Colors.purple.shade50;
        break;
      default:
        icon = Icons.notifications;
        iconColor = const Color(0xFF104f22);
        bgColor = Colors.green.shade50;
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : iconColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: iconColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      final now = DateTime.now();
      final notificationTime = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      final difference = now.difference(notificationTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }
}