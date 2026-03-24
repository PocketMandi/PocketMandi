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
      appBar: AppBar(
        title: const Text('Requests Management'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF104f22), Color(0xFF1a7a33)],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Unlisted Crops'),
            Tab(text: 'Sapling Orders'),
            Tab(text: 'Test Requests'),
            Tab(text: 'Trader Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          UnlistedCropsTab(),
          SaplingOrdersTab(),
          TestRequestsTab(),
          TraderOrdersTab(),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No unlisted crop requests'));
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
          return const Center(child: Text('No unlisted crop requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            var request = requestsList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['cropName'] ?? 'N/A',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Quantity: ${request['quantity']} ${request['unit']}'),
                    Text('Price: ₹${request['pricePerUnit']}/${request['unit']}'),
                    if (request['qualityGrades'] != null)
                      Text('Quality: ${(request['qualityGrades'] as List).join(', ')}'),
                    Text('Mandi: ${request['mandiName'] ?? 'N/A'}'),
                    Text('Location: ${request['selectedLocation'] ?? 'N/A'}'),
                    if (request['message'] != null)
                      Text('Message: ${request['message']}'),
                    Text(
                      'Requested: ${_formatDate(request['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

class SaplingOrdersTab extends StatelessWidget {
  const SaplingOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('saplingorders');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No sapling orders'));
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
          return const Center(child: Text('No sapling orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            var orderInfo = ordersList[index];
            var order = orderInfo['data'] as Map<dynamic, dynamic>;
            var userId = orderInfo['userId'];
            var orderId = orderInfo['orderId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (order['cropImage'] != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              order['cropImage'],
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order['cropName'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text('Type: ${order['saplingType']}'),
                              Text('Quantity: ${order['quantity']} plants'),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('User: ${order['userName']} (${order['userPhone']})'),
                    Text(
                      'Ordered: ${_formatDate(order['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus(
                              context,
                              userId,
                              orderId,
                              'confirmed',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus(
                              context,
                              userId,
                              orderId,
                              'rejected',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    await FirebaseDatabase.instance
        .ref('saplingorders')
        .child(userId)
        .child(orderId)
        .update({
      'status': status,
      'updatedAt': ServerValue.timestamp,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $status')),
    );
  }
}

class TestRequestsTab extends StatelessWidget {
  const TestRequestsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('testrequests');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No test requests'));
        }

        var requestsData = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
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
          return const Center(child: Text('No test requests'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: requestsList.length,
          itemBuilder: (context, index) {
            var requestInfo = requestsList[index];
            var request = requestInfo['data'] as Map<dynamic, dynamic>;
            var userId = requestInfo['userId'];
            var requestId = requestInfo['requestId'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Test Request',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(request['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('User: ${request['userName']} (${request['userPhone']})'),
                    Text('Soil Test: ${request['soilTest'] == true ? 'Yes' : 'No'}'),
                    Text('Water Test: ${request['waterTest'] == true ? 'Yes' : 'No'}'),
                    Text('Address: ${request['address'] ?? 'N/A'}'),
                    if (request['notes'] != null && request['notes'].toString().isNotEmpty)
                      Text('Notes: ${request['notes']}'),
                    Text(
                      'Requested: ${_formatDate(request['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateRequestStatus(
                              context,
                              userId,
                              requestId,
                              'confirmed',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Confirm'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _updateRequestStatus(
                              context,
                              userId,
                              requestId,
                              'rejected',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
    await FirebaseDatabase.instance
        .ref('testrequests')
        .child(userId)
        .child(requestId)
        .update({
      'status': status,
      'updatedAt': ServerValue.timestamp,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request $status')),
    );
  }
}

class TraderOrdersTab extends StatelessWidget {
  const TraderOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseDatabase.instance.ref('addedcropsbyvyapari');

    return StreamBuilder(
      stream: ref.onValue,
      builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.snapshot.value == null) {
          return const Center(child: Text('No trader orders'));
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
          return const Center(child: Text('No trader orders'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: ordersList.length,
          itemBuilder: (context, index) {
            var order = ordersList[index].value as Map<dynamic, dynamic>;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          order['cropType'] ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['status']),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order['status']?.toString().toUpperCase() ?? 'PENDING',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Quantity: ${order['quantity']} ${order['unit']}'),
                    Text('Price: ₹${order['pricePerUnit']}/${order['unit']}'),
                    if (order['qualityGrades'] != null)
                      Text('Quality: ${(order['qualityGrades'] as List).join(', ')}'),
                    if (order['location'] != null) ...[
                      Text('Mandi: ${order['location']['mandiName'] ?? 'N/A'}'),
                      Text('Location: ${order['location']['village']}, ${order['location']['state']}'),
                    ],
                    if (order['requiredDeliveryDate'] != null)
                      Text('Delivery: ${_formatDate(order['requiredDeliveryDate'])}'),
                    if (order['specialInstructions'] != null &&
                        order['specialInstructions'].toString().isNotEmpty)
                      Text('Instructions: ${order['specialInstructions']}'),
                    Text(
                      'Created: ${_formatDate(order['createdAt'])}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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
}
