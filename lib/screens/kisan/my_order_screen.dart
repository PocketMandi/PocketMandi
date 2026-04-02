import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';

class MyOrdersScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const MyOrdersScreen({super.key, this.onBackPressed});

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> myOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  List<Map<String, dynamic>> crops = [];
  List<Map<String, dynamic>> filteredSaplingOrders = [];
  String selectedSaplingFilter = "All";
  List<Map<String, dynamic>> saplingOrders = [];
  List<Map<String, dynamic>> testRequests = [];
  List<Map<String, dynamic>> filteredTestRequests = [];
  String selectedTestFilter = "All";
  bool isLoading = true;
  bool isCropsLoading = true;
  String selectedFilter = "All";

  int totalOrders = 0;
  int pendingOrders = 0;
  int confirmedOrders = 0;
  int deliveredOrders = 0;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMyOrders();
    _loadCrops();
    _loadSaplingOrders();
    _loadTestRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCrops() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('allcrops').once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value;

        setState(() {
          if (data is Map) {
            crops = data.values
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else if (data is List) {
            crops = data
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            crops = [];
          }
          isCropsLoading = false;
        });
      } else {
        setState(() {
          crops = [];
          isCropsLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        crops = [];
        isCropsLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load crops. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
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
    confirmedOrders = orders.where((o) => o['status'] == 'confirmed').length;
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
        filteredOrders = myOrders
            .where((order) => order['status'] == filter.toLowerCase())
            .toList();
      }
    });
  }

  void _applySaplingFilter(String filter) {
    setState(() {
      selectedSaplingFilter = filter;
      if (filter == "All") {
        filteredSaplingOrders = saplingOrders;
      } else {
        filteredSaplingOrders = saplingOrders
            .where(
              (order) =>
                  (order['status'] ?? 'pending').toLowerCase() ==
                  filter.toLowerCase(),
            )
            .toList();
      }
    });
  }

  void _applyTestFilter(String filter) {
    setState(() {
      selectedTestFilter = filter;
      if (filter == "All") {
        filteredTestRequests = testRequests;
      } else {
        filteredTestRequests = testRequests
            .where(
              (request) =>
                  (request['status'] ?? 'pending').toLowerCase() ==
                  filter.toLowerCase(),
            )
            .toList();
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

  IconData _statusIcon(String status) {
    switch (status) {
      case "pending":
        return Icons.schedule;
      case "confirmed":
        return Icons.check_circle_outline;
      case "delivered":
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPlaceNewOrderTab(),
                _buildOrderDashboardTab(),
                _buildSaplingOrdersTab(),
                _buildTestRequestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (widget.onBackPressed != null) {
                        widget.onBackPressed!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Orders",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Manage your crop orders",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: const Color(0xFF104f22),
                unselectedLabelColor: Colors.white,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 8,
                ),
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.all(4),
                tabs: [
                  Tab(
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart, size: 18),
                        SizedBox(height: 4),
                        Text("Order"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.dashboard, size: 18),
                        SizedBox(height: 4),
                        Text("Dashboard"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.eco, size: 18),
                        SizedBox(height: 4),
                        Text("Saplings"),
                      ],
                    ),
                  ),
                  Tab(
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.science, size: 18),
                        SizedBox(height: 4),
                        Text("Tests"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceNewOrderTab() {
    return _buildCropsList();
  }

  Widget _buildCropsList() {
    if (isCropsLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF104f22)),
      );
    }

    if (crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.agriculture_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No crops available",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please check back later",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Select a crop to place order",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E2E),
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.75,
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
                        cropId: (crop['id'] ?? crop['name'] ?? 'unknown')
                            .toString(),
                        cropName: (crop['name'] ?? 'Unknown').toString(),
                        cropImage:
                            (crop['image'] ?? 'assets/images/login_bg.jpg')
                                .toString(),
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(0xFF104f22).withOpacity(0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              child: crop['image'] != null
                                  ? Image.network(
                                      crop['image'].toString(),
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Image.asset(
                                              'assets/images/login_bg.jpg',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                            );
                                          },
                                    )
                                  : Image.asset(
                                      'assets/images/login_bg.jpg',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(24),
                                  topRight: Radius.circular(24),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.3),
                                    Colors.black.withOpacity(0.6),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),
                            if (crop['pricePerUnit'] != null)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF104f22),
                                        Color(0xFF0d3f1c),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF104f22,
                                        ).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.currency_rupee,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      Text(
                                        "${crop['pricePerUnit']}/kg",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(24),
                              bottomRight: Radius.circular(24),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF104f22,
                                    ).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    (crop['name'] ?? 'Unknown').toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF104f22),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              if (crop['nameHindi'] != null)
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      crop['nameHindi'].toString(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderDashboardTab() {
    return isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF104f22)),
          )
        : RefreshIndicator(
            onRefresh: _loadMyOrders,
            color: const Color(0xFF104f22),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  _buildStatisticsCards(),
                  _buildFilterChips(),
                  _buildOrdersList(),
                ],
              ),
            ),
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
                  Icons.inventory_2,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Pending",
                  pendingOrders.toString(),
                  Icons.schedule,
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
                  "Confirmed",
                  confirmedOrders.toString(),
                  Icons.check_circle_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Delivered",
                  deliveredOrders.toString(),
                  Icons.done_all,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTotalSpentCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF104f22).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee,
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
                  "Total Amount",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Pending", "Confirmed", "Delivered"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
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
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: isSelected ? 4 : 0,
              shadowColor: const Color(0xFF104f22).withOpacity(0.3),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrdersList() {
    if (filteredOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No orders found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your orders will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final cropType = order['cropType'] ?? "Unknown";
    final quantity = order['quantity']?.toString() ?? "0";
    final unit = order['unit'] ?? "Kg";
    final grades = (order['qualityGrades'] as List?)?.join(", ") ?? "N/A";
    final location = order['location'] != null
        ? order['location']['deliveryLocation'] ?? "N/A"
        : "N/A";
    final price = (order['pricePerUnit'] ?? 0).toDouble();
    final qty = (order['quantity'] ?? 0).toDouble();
    final amount = (price * qty);
    final status = order['status'] ?? "unknown";
    final deliveryDate = order['requiredDeliveryDate'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor(status).withOpacity(0.15),
                  _statusColor(status).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "₹${amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.agriculture, "Crop", cropType),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.scale,
                        "Quantity",
                        "$quantity $unit",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.grade, "Grade", grades),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.location_on,
                        "Location",
                        location,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.currency_rupee,
                        "Price per kg",
                        "₹${(order['pricePerUnit'] ?? 0).toDouble().toStringAsFixed(2)}/kg",
                      ),
                    ),
                    Expanded(
                      child: deliveryDate != null
                          ? _buildInfoRow(
                              Icons.calendar_today,
                              "Delivery Date",
                              _formatDate(deliveryDate),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}";
  }

  // Test status helper methods
  Color _getTestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTestStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PENDING REVIEW';
      case 'confirmed':
        return 'CONFIRMED';
      case 'rejected':
        return 'REJECTED';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildTestInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _loadSaplingOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref("saplingorders/$userId")
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          temp.add(order);
        });

        temp.sort(
          (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
        );

        setState(() {
          saplingOrders = temp;
          filteredSaplingOrders = temp; // Initialize filtered list
        });
      }
    } catch (e) {
      setState(() {
        saplingOrders = [];
        filteredSaplingOrders = [];
      });
    }
  }

  Future<void> _loadTestRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return;

      final snapshot = await FirebaseDatabase.instance
          .ref("testrequests/$userId")
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          temp.add(request);
        });

        temp.sort(
          (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
        );

        setState(() {
          testRequests = temp;
          filteredTestRequests = temp; // Initialize filtered list
        });
      }
    } catch (e) {
      setState(() {
        testRequests = [];
        filteredTestRequests = [];
      });
    }
  }

  Widget _buildSaplingOrdersTab() {
    return Column(
      children: [
        // Filter Dropdown Section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF104f22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF104f22),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter by Status:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF104f22).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF104f22).withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSaplingFilter,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF104f22),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF104f22),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          [
                            'All',
                            'Pending',
                            'Confirmed',
                            'Delivered',
                            'Rejected',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (value != 'All') ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          value.toLowerCase(),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _applySaplingFilter(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Orders List
        Expanded(child: _buildSaplingOrdersList()),
      ],
    );
  }

  Widget _buildSaplingOrdersList() {
    if (filteredSaplingOrders.isEmpty && saplingOrders.isNotEmpty) {
      // Show filtered empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off,
                size: 48,
                color: const Color(0xFF104f22).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $selectedSaplingFilter Orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No sapling orders found with "$selectedSaplingFilter" status',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _applySaplingFilter('All'),
              icon: const Icon(Icons.clear_all),
              label: const Text('Show All Orders'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF104f22),
              ),
            ),
          ],
        ),
      );
    }

    if (saplingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.eco_outlined,
                size: 64,
                color: const Color(0xFF104f22).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Sapling Orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your sapling orders will appear here',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadSaplingOrders,
      color: const Color(0xFF104f22),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredSaplingOrders.length,
        itemBuilder: (context, index) {
          final order = filteredSaplingOrders[index];
          final status = order['status']?.toString().toLowerCase() ?? 'pending';
          final cropName = order['cropName'] ?? 'Unknown Crop';
          final saplingType = order['saplingType'] ?? 'Standard';
          final quantity = order['quantity']?.toString() ?? '0';
          final createdAt = order['createdAt'] ?? 0;
          final cropImage = order['cropImage'];
          final pricePerUnit = order['pricePerUnit']?.toString() ?? 'N/A';
          final totalAmount = order['totalAmount']?.toString() ?? 'N/A';
          final deliveryAddress = order['deliveryAddress'] ?? 'N/A';
          final contactNumber = order['contactNumber'] ?? 'N/A';

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status Header with Crop Image
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _statusColor(status).withOpacity(0.15),
                        _statusColor(status).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Crop Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: cropImage != null
                            ? Image.network(
                                cropImage,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF104f22,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      color: Color(0xFF104f22),
                                      size: 24,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF104f22,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.eco,
                                  color: Color(0xFF104f22),
                                  size: 24,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cropName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E2E2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Type: $saplingType',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Order #${order['id']?.toString().substring(0, 8) ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _statusIcon(status),
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Order Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // First Row - Quantity and Date
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.eco,
                              'Quantity',
                              '$quantity saplings',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.calendar_today,
                              'Order Date',
                              _formatDate(createdAt),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Second Row - Price and Total
                      if (pricePerUnit != 'N/A' || totalAmount != 'N/A')
                        Row(
                          children: [
                            if (pricePerUnit != 'N/A')
                              Expanded(
                                child: _buildInfoRow(
                                  Icons.currency_rupee,
                                  'Price per Unit',
                                  '₹$pricePerUnit',
                                ),
                              ),
                            if (totalAmount != 'N/A')
                              Expanded(
                                child: _buildInfoRow(
                                  Icons.account_balance_wallet,
                                  'Total Amount',
                                  '₹$totalAmount',
                                ),
                              ),
                          ],
                        ),

                      if (pricePerUnit != 'N/A' || totalAmount != 'N/A')
                        const SizedBox(height: 16),

                      // Third Row - Contact and Address
                      Row(
                        children: [
                          if (contactNumber != 'N/A')
                            Expanded(
                              child: _buildInfoRow(
                                Icons.phone,
                                'Contact',
                                contactNumber,
                              ),
                            ),
                          if (deliveryAddress != 'N/A')
                            Expanded(
                              child: _buildInfoRow(
                                Icons.location_on,
                                'Delivery Address',
                                deliveryAddress,
                              ),
                            ),
                        ],
                      ),

                      // Status-specific information
                      if (status == 'confirmed') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your sapling order has been confirmed. We will contact you for delivery arrangements.',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (status == 'delivered') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your saplings have been successfully delivered. Thank you for your order!',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (status == 'rejected') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Unfortunately, your sapling order could not be processed. Please contact support for assistance.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your sapling order is being processed. We will update you soon with confirmation details.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestRequestsTab() {
    return Column(
      children: [
        // Filter Dropdown Section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF104f22).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.filter_list,
                  color: Color(0xFF104f22),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Filter by Status:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF104f22).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF104f22).withOpacity(0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedTestFilter,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(0xFF104f22),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF104f22),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      items:
                          [
                            'All',
                            'Pending',
                            'Confirmed',
                            'Completed',
                            'Rejected',
                          ].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (value != 'All') ...[
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: _getTestStatusColor(
                                          value.toLowerCase(),
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                  ],
                                  Flexible(
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _applyTestFilter(newValue);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Test Requests List
        Expanded(child: _buildTestRequestsList()),
      ],
    );
  }

  Widget _buildTestRequestsList() {
    if (filteredTestRequests.isEmpty && testRequests.isNotEmpty) {
      // Show filtered empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.filter_list_off,
                size: 48,
                color: const Color(0xFF104f22).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No $selectedTestFilter Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No test requests found with "$selectedTestFilter" status',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => _applyTestFilter('All'),
              icon: const Icon(Icons.clear_all),
              label: const Text('Show All Requests'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF104f22),
              ),
            ),
          ],
        ),
      );
    }

    if (testRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                size: 64,
                color: const Color(0xFF104f22).withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "No Test Requests",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your soil and crop test requests will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTestRequests,
      color: const Color(0xFF104f22),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTestRequests.length,
        itemBuilder: (context, index) {
          final request = filteredTestRequests[index];
          final status =
              request['status']?.toString().toLowerCase() ?? 'pending';
          final testType = request['testType'] ?? 'Soil Test';
          final requestId =
              request['requestId']?.toString() ??
              request['id']?.toString() ??
              'N/A';
          final createdAt = request['createdAt'] ?? 0;
          final address = request['address'] ?? 'N/A';
          final notes = request['notes'] ?? 'No additional notes';
          final contactNumber = request['contactNumber'] ?? 'N/A';
          final preferredDate = request['preferredDate'];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                // Status Header
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getTestStatusColor(status).withOpacity(0.15),
                        _getTestStatusColor(status).withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getTestStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getTestStatusIcon(status),
                          color: _getTestStatusColor(status),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getStatusDisplayText(status),
                              style: TextStyle(
                                color: _getTestStatusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Request #${requestId.length > 8 ? requestId.substring(0, 8) : requestId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getTestStatusColor(status),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          testType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Request Details
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // First Row - Date and Contact
                      Row(
                        children: [
                          Expanded(
                            child: _buildTestInfoRow(
                              Icons.calendar_today,
                              'Requested On',
                              _formatDate(createdAt),
                            ),
                          ),
                          Expanded(
                            child: _buildTestInfoRow(
                              Icons.phone,
                              'Contact',
                              contactNumber,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Second Row - Address
                      _buildTestInfoRow(
                        Icons.location_on,
                        'Test Location',
                        address,
                      ),

                      if (preferredDate != null) ...[
                        const SizedBox(height: 16),
                        _buildTestInfoRow(
                          Icons.event,
                          'Preferred Date',
                          _formatDate(preferredDate),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Notes Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.notes,
                                  size: 16,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Additional Notes',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notes,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2E2E2E),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Status-specific information
                      if (status == 'confirmed') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your test has been confirmed. Our team will contact you soon to schedule the sample collection.',
                                  style: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (status == 'rejected') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Unfortunately, your test request could not be processed. Please contact support for more information.',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (status == 'pending') ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.schedule,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Your test request is being reviewed. We will update you within 24-48 hours.',
                                  style: TextStyle(
                                    color: Colors.orange.shade700,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
