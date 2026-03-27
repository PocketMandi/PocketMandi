import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF104f22),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    final isRead = notification['read'] == true;
                    final title = notification['title'] ?? 'Notification';
                    final body = notification['body'] ?? '';
                    final createdAt = notification['createdAt'];
                    final timeAgo = _getTimeAgo(createdAt);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isRead ? Colors.white : Colors.green.shade50,
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF104f22).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications,
                            color: const Color(0xFF104f22),
                          ),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(body),
                            const SizedBox(height: 4),
                            Text(
                              timeAgo,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
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
