import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  List<Map<String, dynamic>> myOrders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // Load from user-specific path: addedcropsbykissan/userId
      final snapshot = await FirebaseDatabase.instance
          .ref("addedcropsbykissan/$userId")
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> tempOrders = [];

        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          tempOrders.add(order);
        });

        // Sort by creation time (newest first)
        tempOrders.sort(
          (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
        );

        setState(() {
          myOrders = tempOrders;
          isLoading = false;
        });
      } else {
        setState(() {
          myOrders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        myOrders = [];
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load orders. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case "available":
        return Colors.green;
      case "sold":
        return Colors.orange;
      case "cancelled":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final imageUrl = order['imageUrl'] ?? "";
    final cropType = order['cropType'] ?? "Unknown Crop";
    final quantity = order['quantity']?.toString() ?? "0";
    final unit = order['unit'] ?? "Kg";
    final pricePerUnit = order['pricePerUnit']?.toString() ?? "0";
    final status = order['status'] ?? "unknown";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            /// Crop Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFF104f22).withOpacity(0.1),
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF104f22),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: const Color(0xFF104f22).withOpacity(0.8),
                        child: const Icon(
                          Icons.agriculture,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: const Color(0xFF104f22).withOpacity(0.8),
                      child: const Icon(
                        Icons.agriculture,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            /// Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cropType,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Quantity: $quantity $unit",
                    style: const TextStyle(fontSize: 13),
                  ),

                  Text(
                    "Price: ₹$pricePerUnit per $unit",
                    style: const TextStyle(fontSize: 13),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Orders"),
        backgroundColor: const Color(0xFF104f22),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myOrders.isEmpty
          ? const Center(
              child: Text(
                "No orders added yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMyOrders,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myOrders.length,
                itemBuilder: (context, index) {
                  return _buildOrderCard(myOrders[index]);
                },
              ),
            ),
    );
  }
}
