import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> myOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  String selectedFilter = "All";

  int totalOrders = 0;
  int pendingOrders = 0;
  int deliveredOrders = 0;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

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

        tempOrders.sort(
          (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
        );

        _calculateStatistics(tempOrders);

        setState(() {
          myOrders = tempOrders;
          filteredOrders = tempOrders;
          isLoading = false;
        });
      } else {
        setState(() {
          myOrders = [];
          filteredOrders = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        myOrders = [];
        filteredOrders = [];
        isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> orders) {
    totalOrders = orders.length;
    pendingOrders = orders.where((o) => o['status'] == 'pending').length;
    deliveredOrders = orders.where((o) => o['status'] == 'delivered').length;
    
    totalSpent = 0.0;
    for (var order in orders) {
      final price = (order['pricePerUnit'] ?? 0).toDouble();
      final qty = (order['quantity'] ?? 0).toDouble();
      totalSpent += price * qty;
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "All") {
        filteredOrders = myOrders;
      } else {
        filteredOrders = myOrders.where((order) => order['status'] == filter.toLowerCase()).toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("My Orders", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF104f22),
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Place New Order"),
            Tab(text: "Order Dashboard"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPlaceNewOrderTab(),
          _buildOrderDashboardTab(),
        ],
      ),
    );
  }

  Widget _buildPlaceNewOrderTab() {
    return _buildCropsList();
  }

  Widget _buildCropsList() {
    final crops = [
      {"name": "Wheat (गेहूं)", "image": "assets/images/login_bg.jpg", "id": "wheat"},
      {"name": "Maize (मक्का)", "image": "assets/images/maize.jpg", "id": "maize"},
      {"name": "Rice (चावल)", "image": "assets/images/rice.jpg", "id": "rice"},
      {"name": "Potato (आलू)", "image": "assets/images/potato.jpg", "id": "potato"},
      {"name": "Soybean (सोयाबीन)", "image": "assets/images/soybean.jpg", "id": "soybean"},
      {"name": "Green Gram (मूंग)", "image": "assets/images/greengram.jpg", "id": "greengram"},
      {"name": "Onion (प्याज)", "image": "assets/images/onion.jpg", "id": "onion"},
      {"name": "Sugarcane (गन्ना)", "image": "assets/images/sugarcane.jpg", "id": "sugarcane"},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: crops.length,
      itemBuilder: (context, index) {
        final crop = crops[index];
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SelectedCropScreen(
                  cropId: crop['id']!,
                  cropName: crop['name']!,
                  cropImage: crop['image']!,
                ),
              ),
            );
            if (result == true) {
              _loadMyOrders();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                    ),
                    child: Image.asset(
                      crop['image']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    crop['name']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrderDashboardTab() {
    return isLoading
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF104f22)))
        : Column(
            children: [
              _buildStatisticsCards(),
              _buildFilterChips(),
              Expanded(child: _buildOrdersTable()),
            ],
          );
  }

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Orders",
                  totalOrders.toString(),
                  Icons.shopping_bag,
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Pending",
                  pendingOrders.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Delivered",
                  deliveredOrders.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Total Spent",
                  "₹${totalSpent.toStringAsFixed(0)}",
                  Icons.currency_rupee,
                  Colors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Pending", "Confirmed", "Delivered"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) => _applyFilter(filter),
              selectedColor: const Color(0xFF104f22),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersTable() {
    if (filteredOrders.isEmpty) {
      return const Center(
        child: Text(
          "No orders found",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(
            const Color(0xFF104f22).withOpacity(0.1),
          ),
          columns: const [
            DataColumn(label: Text("Crop", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Grade", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Location", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Amount", style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredOrders.map((order) {
            final cropType = order['cropType'] ?? "Unknown";
            final quantity = order['quantity']?.toString() ?? "0";
            final unit = order['unit'] ?? "Kg";
            final grades = (order['qualityGrades'] as List?)?.join(", ") ?? "N/A";
            final location = order['location'] != null
                ? "${order['location']['village'] ?? ''}, ${order['location']['state'] ?? ''}"
                : "N/A";
            final price = (order['pricePerUnit'] ?? 0).toDouble();
            final qty = (order['quantity'] ?? 0).toDouble();
            final amount = (price * qty).toStringAsFixed(2);
            final status = order['status'] ?? "unknown";

            return DataRow(
              cells: [
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      cropType,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text("$quantity $unit")),
                DataCell(Text(grades)),
                DataCell(
                  SizedBox(
                    width: 100,
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text("₹$amount")),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
