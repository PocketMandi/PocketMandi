import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:poket_mandi/services/notification_service.dart';

class OrderSaplingsScreen extends StatefulWidget {
  const OrderSaplingsScreen({super.key});

  @override
  State<OrderSaplingsScreen> createState() => _OrderSaplingsScreenState();
}

class _OrderSaplingsScreenState extends State<OrderSaplingsScreen> {
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
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
          isLoading = false;
        });
      } else {
        setState(() {
          crops = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        crops = [];
        isLoading = false;
      });
    }
  }

  void _showSaplingTypeDialog(Map<String, dynamic> crop) {
    String? selectedType;
    final quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              const Icon(
                Icons.eco,
                color: Color(0xFF104f22),
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                crop['name'] ?? 'Sapling',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF104f22),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Select Sapling Type:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                RadioListTile<String>(
                  title: const Text("Normal"),
                  subtitle: const Text(
                    "Min 10,000 plants order",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: "Normal",
                  groupValue: selectedType,
                  activeColor: const Color(0xFF104f22),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                RadioListTile<String>(
                  title: const Text("Grafted"),
                  subtitle: const Text(
                    "Min 1,000 plants order",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  value: "Grafted",
                  groupValue: selectedType,
                  activeColor: const Color(0xFF104f22),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Quantity:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: quantityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: selectedType == "Grafted"
                        ? "Enter quantity (min 1,000)"
                        : selectedType == "Normal"
                            ? "Enter quantity (min 10,000)"
                            : "Enter quantity",
                    filled: true,
                    fillColor: const Color(0xFFF3F3F3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Icons.numbers,
                      color: Color(0xFF104f22),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (selectedType == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a sapling type'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final quantity = int.tryParse(quantityController.text.trim());
                if (quantity == null || quantity <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid quantity'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedType == "Normal" && quantity < 10000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minimum 10,000 plants required for normal saplings'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (selectedType == "Grafted" && quantity < 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Minimum 1,000 plants required for grafted saplings'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);
                _placeOrder(crop, selectedType!, quantity);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF104f22),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Place Order",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _placeOrder(
    Map<String, dynamic> crop,
    String saplingType,
    int quantity,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('name') ?? 'Unknown';
      final userPhone = prefs.getString('phone') ?? '';

      if (userId == null) {
        throw Exception("User not logged in");
      }

      final ref = FirebaseDatabase.instance
          .ref('saplingorders/$userId')
          .push();

      await ref.set({
        "orderId": ref.key,
        "userId": userId,
        "userName": userName,
        "userPhone": userPhone,
        "cropName": crop['name'] ?? 'Unknown',
        "cropImage": crop['image'] ?? '',
        "saplingType": saplingType,
        "quantity": quantity,
        "status": "pending",
        "createdAt": ServerValue.timestamp,
        "updatedAt": ServerValue.timestamp,
      });

      // Send notification to all admins
      await NotificationService.sendNotificationToAdmins(
        title: 'New Sapling Order',
        body: '$userName ordered $quantity $saplingType ${crop['name']} saplings',
        type: 'sapling_order',
        data: {
          'cropName': crop['name'],
          'userId': userId,
          'orderId': ref.key,
        },
      );

      if (mounted) {
        _showThankYouDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF104f22),
                size: 60,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Thank You!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF104f22),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your sapling order has been placed successfully. Our team will contact you soon.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "आपका पौधा ऑर्डर सफलतापूर्वक दिया गया है। हमारी टीम जल्द ही आपसे संपर्क करेगी।",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
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
                "OK",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF104f22)),
      );
    }

    if (crops.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 80, color: Colors.grey[400]),
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
            "Select a crop to order saplings",
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
              childAspectRatio: 0.85,
            ),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              return _buildCropCard(crop);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> crop) {
    final name = crop['name'] ?? 'Unknown';
    final imagePath = crop['image'] ?? '';

    return GestureDetector(
      onTap: () => _showSaplingTypeDialog(crop),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF104f22).withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF104f22),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF104f22).withOpacity(0.8),
                          child: const Center(
                            child: Icon(
                              Icons.eco,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF104f22).withOpacity(0.8),
                            child: const Center(
                              child: Icon(
                                Icons.eco,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF104f22),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
