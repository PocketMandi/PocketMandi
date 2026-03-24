import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class RequestsManagementScreen extends StatefulWidget {
  const RequestsManagementScreen({Key? key}) : super(key: key);

  @override
  State<RequestsManagementScreen> createState() => _RequestsManagementScreenState();
}

class _RequestsManagementScreenState extends State<RequestsManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.assignment, color: Colors.white, size: 28),
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
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    indicatorPadding: const EdgeInsets.symmetric(horizontal: 8),
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white60,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                    tabs: const [
                      Tab(
                        child: Row(
                          children: [
                            Icon(Icons.grass, size: 18),
                            SizedBox(width: 8),
                            Text('Unlisted Crops'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            Icon(Icons.local_florist, size: 18),
                            SizedBox(width: 8),
                            Text('Sapling Orders'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            Icon(Icons.science, size: 18),
                            SizedBox(width: 8),
                            Text('Test Requests'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 18),
                            SizedBox(width: 8),
                            Text('Trader Orders'),
                          ],
                        ),
                      ),
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
                  UnlistedCropsTab(),
                  SaplingOrdersTab(),
                  TestRequestsTab(),
                  TraderOrdersTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class UnlistedCropsTab extends StatelessWidget {
  const UnlistedCropsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('requestednewcropbyvyapari');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF104f22)));
        }

        if (snapshot.data!.snapshot.value == null) {
          return _buildEmptyState('No unlisted crop requests', Icons.grass);
        }

        var requestsData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            var request = requestsList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF104f22).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.grass, color: Colors.white, size: 28),
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
                                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(request['createdAt']),
                                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.orange.shade600],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'PENDING',
                              style: TextStyle(
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
                            _buildInfoRow(Icons.shopping_basket, 'Quantity', '${request['quantity']} ${request['unit']}'),
                            const Divider(height: 20),
                            _buildInfoRow(Icons.currency_rupee, 'Price', '₹${request['pricePerUnit']}/${request['unit']}'),
                            if (request['qualityGrades'] != null) const Divider(height: 20),
                            if (request['qualityGrades'] != null)
                              _buildInfoRow(Icons.star, 'Quality', (request['qualityGrades'] as List).join(', ')),
                            const Divider(height: 20),
                            _buildInfoRow(Icons.store, 'Mandi', request['mandiName'] ?? 'N/A'),
                            const Divider(height: 20),
                            _buildInfoRow(Icons.location_on, 'Location', request['selectedLocation'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      if (request['message'] != null && request['message'].toString().isNotEmpty)
                        const SizedBox(height: 16),
                      if (request['message'] != null && request['message'].toString().isNotEmpty)
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
                                child: Icon(Icons.message, size: 18, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Message',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request['message'],
                                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

// Keep other tabs same as before
class SaplingOrdersTab extends StatelessWidget {
  const SaplingOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Sapling Orders'));
  }
}

class TestRequestsTab extends StatelessWidget {
  const TestRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Test Requests'));
  }
}

class TraderOrdersTab extends StatelessWidget {
  const TraderOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Trader Orders'));
  }
}
