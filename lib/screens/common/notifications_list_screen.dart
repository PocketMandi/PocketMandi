import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/admin/requests_management_screen.dart';

class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsListScreen> createState() =>
      _NotificationsListScreenState();
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

      // Limit notifications to last 100 for better performance
      final snapshot = await FirebaseDatabase.instance
          .ref('notifications/$userId')
          .orderByChild('createdAt')
          .limitToLast(100)
          .once();

      if (snapshot.snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final List<Map<String, dynamic>> loadedNotifications = [];

        data.forEach((key, value) {
          final notification = Map<String, dynamic>.from(value as Map);
          notification['id'] = key;
          loadedNotifications.add(notification);
        });

        // Sort by timestamp descending (newest first)
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
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final data = notification['data'] as Map<dynamic, dynamic>?;
    final type = data?['type'];

    // Mark as read
    _markAsRead(notification['id']);

    // Handle broadcast notifications - just mark as read, no navigation
    if (type == 'broadcast') {
      return; // Just mark as read and stay on notifications screen
    }

    // Navigate based on notification type (only for admin notifications)
    if (type != null) {
      int tabIndex = 0;

      switch (type) {
        case 'crop_request':
          tabIndex = 0; // Farmer Unlisted
          break;
        case 'crop_order':
          tabIndex = 2; // Farmer Crops
          break;
        case 'sapling_order':
          tabIndex = 4; // Sapling Orders
          break;
        case 'test_request':
          tabIndex = 5; // Test Requests
          break;
        case 'new_user':
          // Navigate to users management
          Navigator.pop(context);
          return;
        default:
          return; // Don't navigate for unknown types
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RequestsManagementScreenWithTab(initialTab: tabIndex),
        ),
      );
    }
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
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationCard(notification);
                          },
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
      case 'crop_request':
        icon = Icons.grass;
        iconColor = Colors.green;
        bgColor = Colors.green.shade50;
        break;
      case 'crop_order':
        icon = Icons.shopping_cart;
        iconColor = Colors.teal;
        bgColor = Colors.teal.shade50;
        break;
      case 'sapling_order':
        icon = Icons.local_florist;
        iconColor = Colors.purple;
        bgColor = Colors.purple.shade50;
        break;
      case 'test_request':
        icon = Icons.science;
        iconColor = Colors.blue;
        bgColor = Colors.blue.shade50;
        break;
      case 'new_user':
        icon = Icons.person_add;
        iconColor = Colors.orange;
        bgColor = Colors.orange.shade50;
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
                child: Icon(icon, color: iconColor, size: 24),
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
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
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
      final notificationTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp as int,
      );
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

// Wrapper widget to open RequestsManagementScreen with specific tab
class RequestsManagementScreenWithTab extends StatefulWidget {
  final int initialTab;

  const RequestsManagementScreenWithTab({Key? key, required this.initialTab})
    : super(key: key);

  @override
  State<RequestsManagementScreenWithTab> createState() =>
      _RequestsManagementScreenWithTabState();
}

class _RequestsManagementScreenWithTabState
    extends State<RequestsManagementScreenWithTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 6,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Requests Management',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Manage all incoming requests',
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
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 13,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: const [
                      Tab(text: 'Farmer\nUnlisted'),
                      Tab(text: 'Trader\nUnlisted'),
                      Tab(text: 'Farmer\nCrops'),
                      Tab(text: 'Trader\nCrops'),
                      Tab(text: 'Sapling\nOrders'),
                      Tab(text: 'Test\nRequests'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[100],
              child: TabBarView(
                controller: _tabController,
                children: const [
                  FarmerUnlistedCropsTab(),
                  TraderUnlistedCropsTab(),
                  FarmerCropsTab(),
                  TraderCropsTab(),
                  SaplingOrdersTab(),
                  TestRequestsTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
