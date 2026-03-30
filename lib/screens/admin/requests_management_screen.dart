import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'farmer_unlisted_dialog.dart';
import 'trader_unlisted_dialog.dart';
import 'farmer_crops_dialog.dart';
import 'package:poket_mandi/services/notification_service.dart';

class RequestsManagementScreenWithTab extends StatefulWidget {
  final int initialTab;
  
  const RequestsManagementScreenWithTab({Key? key, this.initialTab = 0}) : super(key: key);

  @override
  State<RequestsManagementScreenWithTab> createState() => _RequestsManagementScreenWithTabState();
}

class _RequestsManagementScreenWithTabState extends State<RequestsManagementScreenWithTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.2),
          ),
        ],
      ),
    );
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
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                    tabAlignment: TabAlignment.start,
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.zero,
                    tabs: [
                      _buildTab(Icons.grass, 'Farmer\nUnlisted'),
                      _buildTab(Icons.store, 'Trader\nUnlisted'),
                      _buildTab(Icons.agriculture, 'Farmer\nCrops'),
                      _buildTab(Icons.shopping_bag, 'Trader\nCrops'),
                      _buildTab(Icons.local_florist, 'Sapling\nOrders'),
                      _buildTab(Icons.science, 'Test\nRequests'),
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

class RequestsManagementScreen extends StatefulWidget {
  const RequestsManagementScreen({Key? key}) : super(key: key);

  @override
  State<RequestsManagementScreen> createState() =>
      _RequestsManagementScreenState();
}

class _RequestsManagementScreenState extends State<RequestsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTab(IconData icon, String label) {
    return Tab(
      height: 70,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(height: 1.2),
          ),
        ],
      ),
    );
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
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
                    tabAlignment: TabAlignment.start,
                    indicatorColor: Colors.white,
                    indicatorWeight: 4,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    padding: EdgeInsets.zero,
                    tabs: [
                      _buildTab(Icons.grass, 'Farmer\nUnlisted'),
                      _buildTab(Icons.store, 'Trader\nUnlisted'),
                      _buildTab(Icons.agriculture, 'Farmer\nCrops'),
                      _buildTab(Icons.shopping_bag, 'Trader\nCrops'),
                      _buildTab(Icons.local_florist, 'Sapling\nOrders'),
                      _buildTab(Icons.science, 'Test\nRequests'),
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

class FarmerUnlistedCropsTab extends StatelessWidget {
  const FarmerUnlistedCropsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('requestednewcrop');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState(
            'No farmer unlisted crop requests',
            Icons.grass,
          );
        }

        var requestsData =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var requestsList = <MapEntry>[];

        requestsData.forEach((userId, userRequests) {
          if (userRequests is Map) {
            userRequests.forEach((requestId, request) {
              requestsList.add(MapEntry('$userId/$requestId', request));
            });
          }
        });

        if (requestsList.isEmpty) {
          return _buildEmptyState(
            'No farmer unlisted crop requests',
            Icons.grass,
          );
        }

        requestsList.sort((a, b) {
          var aTime = (a.value as Map)['createdAt'] ?? 0;
          var bTime = (b.value as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            var request = requestsList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () => showFarmerRequestDetails(context, request),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.green.shade50.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF104f22),
                                    Color(0xFF1a7a33),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF104f22,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grass,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['cropName'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E2E2E),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(request['createdAt']),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _getStatusGradient(request['status']),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(
                                      request['status'],
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                (request['status']?.toString().toUpperCase() ??
                                    'PENDING'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.person,
                                'Farmer',
                                '${request['userName']} (${request['userPhone']})',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                showFarmerRequestDetails(context, request),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text(
                              'View Complete Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104f22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: request['status'] ?? 'pending',
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF104f22),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E2E2E),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pending,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Pending'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'confirmed',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Confirmed'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'delivered',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Delivered'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'rejected',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Rejected'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _updateStatus(
                                    context,
                                    requestsList[index].key,
                                    value,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String path,
    String status,
  ) async {
    final parts = path.split('/');
    final userId = parts[0];
    final requestId = parts[1];

    print('DEBUG: Updating status for farmer userId: $userId');

    await FirebaseDatabase.instance
        .ref('requestednewcrop')
        .child(userId)
        .child(requestId)
        .update({'status': status, 'updatedAt': ServerValue.timestamp});

    // Send notification to farmer
    final snapshot = await FirebaseDatabase.instance
        .ref('requestednewcrop/$userId/$requestId')
        .once();

    if (snapshot.snapshot.value != null) {
      final request = snapshot.snapshot.value as Map;
      final cropName = request['cropName'] ?? 'Crop';

      // Verify this is a farmer/kisan user
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/$userId')
          .once();
      
      if (userSnapshot.snapshot.value != null) {
        final userData = userSnapshot.snapshot.value as Map;
        final userRole = userData['role'];
        print('DEBUG: Target user role: $userRole');
        
        if (userRole != 'kisan' && userRole != 'farmer') {
          print('ERROR: Attempting to send notification to non-farmer user!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid user role')),
          );
          return;
        }
      }

      String notificationTitle = '';
      String notificationBody = '';

      switch (status) {
        case 'confirmed':
          notificationTitle = 'Request Confirmed ✅';
          notificationBody =
              'Your request for $cropName has been confirmed by admin.';
          break;
        case 'delivered':
          notificationTitle = 'Request Delivered 🚚';
          notificationBody = 'Your request for $cropName has been delivered.';
          break;
        case 'rejected':
          notificationTitle = 'Request Rejected ❌';
          notificationBody = 'Your request for $cropName has been rejected.';
          break;
        default:
          notificationTitle = 'Request Status Updated';
          notificationBody =
              'Your request for $cropName status has been updated to $status.';
      }

      print('DEBUG: Sending notification to farmer userId: $userId');
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: notificationTitle,
        body: notificationBody,
        type: 'crop_request_status',
        data: {'requestId': requestId, 'cropName': cropName, 'status': status},
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<Color> _getStatusGradient(String? status) {
    switch (status) {
      case 'confirmed':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'delivered':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'rejected':
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.orange.shade400, Colors.orange.shade600];
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class TraderUnlistedCropsTab extends StatelessWidget {
  const TraderUnlistedCropsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('requestednewcropbyvyapari');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No unlisted crop requests', Icons.grass);
        }

        var requestsData =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var requestsList = <MapEntry>[];

        requestsData.forEach((userId, userRequests) {
          if (userRequests is Map) {
            userRequests.forEach((requestId, request) {
              requestsList.add(MapEntry('$userId/$requestId', request));
            });
          }
        });

        if (requestsList.isEmpty) {
          return _buildEmptyState('No unlisted crop requests', Icons.grass);
        }

        // Sort by timestamp descending (newest first)
        requestsList.sort((a, b) {
          var aTime = (a.value as Map)['createdAt'] ?? 0;
          var bTime = (b.value as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            var request = requestsList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: InkWell(
                onTap: () => showTraderRequestDetails(context, request),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.green.shade50.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF104f22),
                                    Color(0xFF1a7a33),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF104f22,
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.grass,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request['cropName'] ?? 'N/A',
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E2E2E),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: Colors.grey[500],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(request['createdAt']),
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _getStatusGradient(request['status']),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getStatusColor(
                                      request['status'],
                                    ).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                (request['status']?.toString().toUpperCase() ??
                                    'PENDING'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow(
                                Icons.person,
                                'Trader',
                                '${request['userName']} (${request['userPhone']})',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                showTraderRequestDetails(context, request),
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text(
                              'View Complete Details',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104f22),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: request['status'] ?? 'pending',
                              isExpanded: true,
                              icon: const Icon(
                                Icons.arrow_drop_down,
                                color: Color(0xFF104f22),
                              ),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E2E2E),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'pending',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.pending,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Pending'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'confirmed',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        size: 18,
                                        color: Colors.green,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Confirmed'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'delivered',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_shipping,
                                        size: 18,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Delivered'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'rejected',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      SizedBox(width: 8),
                                      Text('Rejected'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  _updateTraderStatus(
                                    context,
                                    requestsList[index].key,
                                    value,
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateTraderStatus(
    BuildContext context,
    String path,
    String status,
  ) async {
    final parts = path.split('/');
    final userId = parts[0];
    final requestId = parts[1];

    print('DEBUG: Updating status for trader userId: $userId');

    try {
      await FirebaseDatabase.instance
          .ref('requestednewcropbyvyapari')
          .child(userId)
          .child(requestId)
          .update({'status': status, 'updatedAt': ServerValue.timestamp});

      // Send notification to trader
      final snapshot = await FirebaseDatabase.instance
          .ref('requestednewcropbyvyapari/$userId/$requestId')
          .once();

      if (snapshot.snapshot.value != null) {
        final request = snapshot.snapshot.value as Map;
        final cropName = request['cropName'] ?? 'Crop';

        // Verify this is a trader/vyapari user
        final userSnapshot = await FirebaseDatabase.instance
            .ref('users/$userId')
            .once();
        
        if (userSnapshot.snapshot.value != null) {
          final userData = userSnapshot.snapshot.value as Map;
          final userRole = userData['role'];
          print('DEBUG: Target user role: $userRole');
          
          if (userRole != 'trader' && userRole != 'vyapari') {
            print('ERROR: Attempting to send notification to non-trader user!');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Error: Invalid user role')),
              );
            }
            return;
          }
        }

        String notificationTitle = '';
        String notificationBody = '';

        switch (status) {
          case 'confirmed':
            notificationTitle = 'Request Confirmed ✅';
            notificationBody =
                'Your request for $cropName has been confirmed by admin.';
            break;
          case 'delivered':
            notificationTitle = 'Request Delivered 🚚';
            notificationBody = 'Your request for $cropName has been delivered.';
            break;
          case 'rejected':
            notificationTitle = 'Request Rejected ❌';
            notificationBody = 'Your request for $cropName has been rejected.';
            break;
          default:
            notificationTitle = 'Request Status Updated';
            notificationBody =
                'Your request for $cropName status has been updated to $status.';
        }

        print('DEBUG: Sending notification to trader userId: $userId');
        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          type: 'crop_request_status',
          data: {'requestId': requestId, 'cropName': cropName, 'status': status},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
      }
    } catch (e) {
      print('ERROR: Failed to update status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<Color> _getStatusGradient(String? status) {
    switch (status) {
      case 'confirmed':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'delivered':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'rejected':
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.orange.shade400, Colors.orange.shade600];
    }
  }
}

class SaplingOrdersTab extends StatelessWidget {
  const SaplingOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('saplingorders');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No sapling orders', Icons.local_florist);
        }

        var ordersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var ordersList = <Map<String, dynamic>>[];

        ordersData.forEach((userId, userOrders) {
          if (userOrders is Map) {
            userOrders.forEach((orderId, order) {
              ordersList.add({
                'userId': userId,
                'orderId': orderId,
                'data': order,
              });
            });
          }
        });

        if (ordersList.isEmpty) {
          return _buildEmptyState('No sapling orders', Icons.local_florist);
        }

        // Sort by timestamp descending
        ordersList.sort((a, b) {
          var aTime = (a['data'] as Map)['createdAt'] ?? 0;
          var bTime = (b['data'] as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ordersList.length,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            var orderInfo = ordersList[index];
            var order = orderInfo['data'] as Map<dynamic, dynamic>;
            var userId = orderInfo['userId'];
            var orderId = orderInfo['orderId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.purple.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade600,
                                  Colors.purple.shade800,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_florist,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['cropName'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(order['createdAt']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    _getStatusColor(order['status']) ==
                                        Colors.green
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ]
                                    : _getStatusColor(order['status']) ==
                                          Colors.red
                                    ? [Colors.red.shade400, Colors.red.shade600]
                                    : [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    order['status'],
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              order['status']?.toString().toUpperCase() ??
                                  'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.shopping_cart,
                              'Quantity',
                              '${order['quantity']} plants',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.person,
                              'Customer',
                              '${order['userName']} (${order['userPhone']})',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.category,
                              'Type',
                              order['saplingType'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: order['status'] ?? 'pending',
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF104f22),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pending'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'confirmed',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Confirmed'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Rejected'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateOrderStatus(
                                  context,
                                  userId,
                                  orderId,
                                  value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _updateOrderStatus(
    BuildContext context,
    String userId,
    String orderId,
    String status,
  ) async {
    try {
      await FirebaseDatabase.instance
          .ref('saplingorders')
          .child(userId)
          .child(orderId)
          .update({'status': status, 'updatedAt': ServerValue.timestamp});

      final snapshot = await FirebaseDatabase.instance
          .ref('saplingorders/$userId/$orderId')
          .once();

      if (snapshot.snapshot.value != null) {
        final order = snapshot.snapshot.value as Map;
        final cropName = order['cropName'] ?? 'Sapling';

        String notificationTitle = '';
        String notificationBody = '';

        switch (status) {
          case 'confirmed':
            notificationTitle = 'Sapling Order Confirmed ✅';
            notificationBody =
                'Your sapling order for $cropName has been confirmed by admin.';
            break;
          case 'rejected':
            notificationTitle = 'Sapling Order Rejected ❌';
            notificationBody = 'Your sapling order for $cropName has been rejected.';
            break;
          default:
            notificationTitle = 'Sapling Order Status Updated';
            notificationBody =
                'Your sapling order for $cropName status has been updated to $status.';
        }

        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          type: 'sapling_order_status',
          data: {'orderId': orderId, 'cropName': cropName, 'status': status},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class TestRequestsTab extends StatelessWidget {
  const TestRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('testrequests');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No test requests', Icons.science);
        }

        var requestsData =
            snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var requestsList = <Map<String, dynamic>>[];

        requestsData.forEach((userId, userRequests) {
          if (userRequests is Map) {
            userRequests.forEach((requestId, request) {
              requestsList.add({
                'userId': userId,
                'requestId': requestId,
                'data': request,
              });
            });
          }
        });

        if (requestsList.isEmpty) {
          return _buildEmptyState('No test requests', Icons.science);
        }

        // Sort by timestamp descending
        requestsList.sort((a, b) {
          var aTime = (a['data'] as Map)['createdAt'] ?? 0;
          var bTime = (b['data'] as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requestsList.length,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            var requestInfo = requestsList[index];
            var request = requestInfo['data'] as Map<dynamic, dynamic>;
            var userId = requestInfo['userId'];
            var requestId = requestInfo['requestId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.blue.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600,
                                  Colors.blue.shade800,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.science,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Test Request',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(request['createdAt']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    _getStatusColor(request['status']) ==
                                        Colors.green
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ]
                                    : _getStatusColor(request['status']) ==
                                          Colors.red
                                    ? [Colors.red.shade400, Colors.red.shade600]
                                    : [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    request['status'],
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              request['status']?.toString().toUpperCase() ??
                                  'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: request['soilTest'] == true
                                    ? Colors.green.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: request['soilTest'] == true
                                      ? Colors.green.shade200
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    request['soilTest'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: request['soilTest'] == true
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Soil Test',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: request['soilTest'] == true
                                          ? Colors.green.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: request['waterTest'] == true
                                    ? Colors.blue.shade50
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: request['waterTest'] == true
                                      ? Colors.blue.shade200
                                      : Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    request['waterTest'] == true
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: request['waterTest'] == true
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Water Test',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: request['waterTest'] == true
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.person,
                              'Customer',
                              '${request['userName']} (${request['userPhone']})',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.location_on,
                              'Address',
                              request['address'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                      if (request['notes'] != null &&
                          request['notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.note,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request['notes'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: request['status'] ?? 'pending',
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF104f22),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pending'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'confirmed',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Confirmed'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Rejected'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateRequestStatus(
                                  context,
                                  userId,
                                  requestId,
                                  value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _updateRequestStatus(
    BuildContext context,
    String userId,
    String requestId,
    String status,
  ) async {
    try {
      await FirebaseDatabase.instance
          .ref('testrequests')
          .child(userId)
          .child(requestId)
          .update({'status': status, 'updatedAt': ServerValue.timestamp});

      final snapshot = await FirebaseDatabase.instance
          .ref('testrequests/$userId/$requestId')
          .once();

      if (snapshot.snapshot.value != null) {
        final request = snapshot.snapshot.value as Map;
        final soilTest = request['soilTest'] == true;
        final waterTest = request['waterTest'] == true;
        String testType = '';
        if (soilTest && waterTest) {
          testType = 'Soil & Water Test';
        } else if (soilTest) {
          testType = 'Soil Test';
        } else if (waterTest) {
          testType = 'Water Test';
        } else {
          testType = 'Test';
        }

        String notificationTitle = '';
        String notificationBody = '';

        switch (status) {
          case 'confirmed':
            notificationTitle = 'Test Request Confirmed ✅';
            notificationBody =
                'Your $testType request has been confirmed by admin.';
            break;
          case 'rejected':
            notificationTitle = 'Test Request Rejected ❌';
            notificationBody = 'Your $testType request has been rejected.';
            break;
          default:
            notificationTitle = 'Test Request Status Updated';
            notificationBody =
                'Your $testType request status has been updated to $status.';
        }

        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          type: 'test_request_status',
          data: {'requestId': requestId, 'testType': testType, 'status': status},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

class FarmerCropsTab extends StatelessWidget {
  const FarmerCropsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('addedcropsbykissan');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No farmer crop listings', Icons.agriculture);
        }

        var cropsData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var cropsList = <MapEntry>[];

        cropsData.forEach((userId, userCrops) {
          if (userCrops is Map) {
            userCrops.forEach((cropId, crop) {
              cropsList.add(MapEntry('$userId/$cropId', crop));
            });
          }
        });

        if (cropsList.isEmpty) {
          return _buildEmptyState('No farmer crop listings', Icons.agriculture);
        }

        cropsList.sort((a, b) {
          var aTime = (a.value as Map)['createdAt'] ?? 0;
          var bTime = (b.value as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cropsList.length,
          itemBuilder: (context, index) {
            var crop = cropsList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.teal.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.teal.shade600,
                                  Colors.teal.shade800,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.teal.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.agriculture,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  crop['cropType'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(crop['createdAt']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _getStatusGradient(crop['status']),
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    crop['status'],
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              (crop['status']?.toString().toUpperCase() ??
                                  'PENDING'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (crop['imageUrl'] != null) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            crop['imageUrl'],
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              Icons.shopping_basket,
                              'Quantity',
                              '${crop['quantity']} ${crop['unit']}',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.currency_rupee,
                              'Price',
                              '₹${crop['pricePerUnit']}/${crop['unit']}',
                            ),
                            const Divider(height: 20),
                            _buildInfoRow(
                              Icons.person,
                              'Farmer',
                              '${crop['userName']} (${crop['userPhone']})',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => showFarmerCropDetails(context, crop),
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text(
                            'View Complete Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF104f22),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: crop['status'] ?? 'pending',
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF104f22),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pending'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'confirmed',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Confirmed'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'delivered',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Delivered'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Rejected'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateStatus(
                                  context,
                                  cropsList[index].key,
                                  value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(
    BuildContext context,
    String path,
    String status,
  ) async {
    final parts = path.split('/');
    final userId = parts[0];
    final cropId = parts[1];

    print('DEBUG: Updating farmer crop status for userId: $userId');

    await FirebaseDatabase.instance
        .ref('addedcropsbykissan')
        .child(userId)
        .child(cropId)
        .update({'status': status, 'updatedAt': ServerValue.timestamp});

    // Send notification to farmer
    final snapshot = await FirebaseDatabase.instance
        .ref('addedcropsbykissan/$userId/$cropId')
        .once();

    if (snapshot.snapshot.value != null) {
      final crop = snapshot.snapshot.value as Map;
      final cropType = crop['cropType'] ?? 'Crop';

      // Verify this is a farmer/kisan user
      final userSnapshot = await FirebaseDatabase.instance
          .ref('users/$userId')
          .once();
      
      if (userSnapshot.snapshot.value != null) {
        final userData = userSnapshot.snapshot.value as Map;
        final userRole = userData['role'];
        print('DEBUG: Target user role: $userRole');
        
        if (userRole != 'kisan' && userRole != 'farmer') {
          print('ERROR: Attempting to send notification to non-farmer user!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Invalid user role')),
          );
          return;
        }
      }

      String notificationTitle = '';
      String notificationBody = '';

      switch (status) {
        case 'confirmed':
          notificationTitle = 'Crop Listing Confirmed ✅';
          notificationBody =
              'Your $cropType listing has been confirmed by admin.';
          break;
        case 'delivered':
          notificationTitle = 'Crop Delivered 🚚';
          notificationBody = 'Your $cropType has been marked as delivered.';
          break;
        case 'rejected':
          notificationTitle = 'Crop Listing Rejected ❌';
          notificationBody = 'Your $cropType listing has been rejected.';
          break;
        default:
          notificationTitle = 'Crop Status Updated';
          notificationBody =
              'Your $cropType listing status has been updated to $status.';
      }

      print('DEBUG: Sending notification to farmer userId: $userId');
      await NotificationService.sendNotificationToUser(
        userId: userId,
        title: notificationTitle,
        body: notificationBody,
        type: 'crop_order_status',
        data: {'cropId': cropId, 'cropType': cropType, 'status': status},
      );
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Status updated to $status')));
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'delivered':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  List<Color> _getStatusGradient(String? status) {
    switch (status) {
      case 'confirmed':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'delivered':
        return [Colors.blue.shade400, Colors.blue.shade600];
      case 'rejected':
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.orange.shade400, Colors.orange.shade600];
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

class TraderCropsTab extends StatelessWidget {
  const TraderCropsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('addedcropsbyvyapari');

    return StreamBuilder(
      stream: ref.limitToLast(50).onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          );
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No trader orders', Icons.shopping_bag);
        }

        var ordersData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
        var ordersList = <MapEntry>[];

        ordersData.forEach((userId, userOrders) {
          if (userOrders is Map) {
            userOrders.forEach((orderId, order) {
              ordersList.add(MapEntry('$userId/$orderId', order));
            });
          }
        });

        if (ordersList.isEmpty) {
          return _buildEmptyState('No trader orders', Icons.shopping_bag);
        }

        // Sort by timestamp descending
        ordersList.sort((a, b) {
          var aTime = (a.value as Map)['createdAt'] ?? 0;
          var bTime = (b.value as Map)['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ordersList.length,
          cacheExtent: 500,
          itemBuilder: (context, index) {
            var order = ordersList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.orange.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.orange.shade600,
                                  Colors.orange.shade800,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.shopping_bag,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['cropType'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E2E),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(order['createdAt']),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors:
                                    _getStatusColor(order['status']) ==
                                        Colors.green
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ]
                                    : _getStatusColor(order['status']) ==
                                          Colors.red
                                    ? [Colors.red.shade400, Colors.red.shade600]
                                    : [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _getStatusColor(
                                    order['status'],
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              order['status']?.toString().toUpperCase() ??
                                  'PENDING',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.shopping_cart,
                                    color: Colors.green.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${order['quantity']} ${order['unit']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Quantity',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.currency_rupee,
                                    color: Colors.orange.shade700,
                                    size: 22,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${order['pricePerUnit']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Per ${order['unit']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (order['qualityGrades'] != null) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: (order['qualityGrades'] as List).map((
                            grade,
                          ) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.amber.shade200,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    grade.toString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            if (order['location'] != null) ...[
                              _buildInfoRow(
                                Icons.store,
                                'Mandi',
                                order['location']['mandiName'] ?? 'N/A',
                              ),
                              const Divider(height: 20),
                              _buildInfoRow(
                                Icons.location_on,
                                'Location',
                                '${order['location']['village']}, ${order['location']['state']}',
                              ),
                            ],
                            if (order['requiredDeliveryDate'] != null) ...[
                              if (order['location'] != null)
                                const Divider(height: 20),
                              _buildInfoRow(
                                Icons.local_shipping,
                                'Delivery',
                                _formatDate(order['requiredDeliveryDate']),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (order['specialInstructions'] != null &&
                          order['specialInstructions']
                              .toString()
                              .isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Instructions',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      order['specialInstructions'],
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: order['status'] ?? 'pending',
                            isExpanded: true,
                            icon: const Icon(
                              Icons.arrow_drop_down,
                              color: Color(0xFF104f22),
                            ),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E2E2E),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'pending',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pending,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Pending'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'confirmed',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Confirmed'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'delivered',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping,
                                      size: 18,
                                      color: Colors.blue,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Delivered'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'rejected',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.cancel,
                                      size: 18,
                                      color: Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text('Rejected'),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                _updateTraderCropStatus(
                                  context,
                                  ordersList[index].key,
                                  value,
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF2E2E2E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'confirmed':
      case 'delivered':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      var date = DateTime.fromMillisecondsSinceEpoch(timestamp as int);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Future<void> _updateTraderCropStatus(
    BuildContext context,
    String path,
    String status,
  ) async {
    final parts = path.split('/');
    final userId = parts[0];
    final orderId = parts[1];

    try {
      await FirebaseDatabase.instance
          .ref('addedcropsbyvyapari')
          .child(userId)
          .child(orderId)
          .update({'status': status, 'updatedAt': ServerValue.timestamp});

      final snapshot = await FirebaseDatabase.instance
          .ref('addedcropsbyvyapari/$userId/$orderId')
          .once();

      if (snapshot.snapshot.value != null) {
        final order = snapshot.snapshot.value as Map;
        final cropType = order['cropType'] ?? 'Crop';

        String notificationTitle = '';
        String notificationBody = '';

        switch (status) {
          case 'confirmed':
            notificationTitle = 'Order Confirmed ✅';
            notificationBody =
                'Your $cropType order has been confirmed by admin.';
            break;
          case 'delivered':
            notificationTitle = 'Order Delivered 🚚';
            notificationBody = 'Your $cropType order has been delivered.';
            break;
          case 'rejected':
            notificationTitle = 'Order Rejected ❌';
            notificationBody = 'Your $cropType order has been rejected.';
            break;
          default:
            notificationTitle = 'Order Status Updated';
            notificationBody =
                'Your $cropType order status has been updated to $status.';
        }

        await NotificationService.sendNotificationToUser(
          userId: userId,
          title: notificationTitle,
          body: notificationBody,
          type: 'crop_order_status',
          data: {'orderId': orderId, 'cropType': cropType, 'status': status},
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated to $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
