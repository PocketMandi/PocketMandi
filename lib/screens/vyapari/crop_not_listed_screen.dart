import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';

class CropNotListedScreen extends StatefulWidget {
  const CropNotListedScreen({super.key});

  @override
  State<CropNotListedScreen> createState() => _CropNotListedScreenState();
}

class _CropNotListedScreenState extends State<CropNotListedScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController cropController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController newAddressController = TextEditingController();
  final TextEditingController newMandiController = TextEditingController();

  String? selectedLocation;
  String? selectedMandi;
  String? selectedUnit = "Kg";
  Set<String> selectedQualities = {};
  bool isLoading = false;
  String savedAddress = "";
  bool showAddNewAddress = false;
  bool showAddNewMandi = false;
  Map<String, dynamic> userProfile = {};

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/$userId')
            .once();

        if (snapshot.snapshot.value != null) {
          final data = snapshot.snapshot.value as Map;
          setState(() {
            userProfile = Map<String, dynamic>.from(data);

            // Build complete address from all available fields
            final village = data['village']?.toString().trim() ?? '';
            final state = data['state']?.toString().trim() ?? '';
            final country = data['country']?.toString().trim() ?? '';
            final address = data['address']?.toString().trim() ?? '';
            final pincode = data['pincode']?.toString().trim() ?? '';
            final mandiName = data['mandiName']?.toString().trim() ?? '';

            // Always build complete address with all components
            List<String> addressParts = [];

            // Add mandi name if available (for vyapari)
            if (mandiName.isNotEmpty) {
              addressParts.add(mandiName);
            }

            // Add village/town
            if (village.isNotEmpty) {
              addressParts.add(village);
            }

            // Add state
            if (state.isNotEmpty) {
              addressParts.add(state);
            }

            // Add country
            if (country.isNotEmpty) {
              addressParts.add(country);
            }

            // Always add pincode at the end if available
            if (pincode.isNotEmpty) {
              addressParts.add('PIN: $pincode');
            }

            // If we have components, use them; otherwise fall back to address field
            if (addressParts.isNotEmpty) {
              savedAddress = addressParts.join(', ');
            } else if (address.isNotEmpty) {
              // If no components but address field exists, add pincode to it
              savedAddress = pincode.isNotEmpty
                  ? '$address, PIN: $pincode'
                  : address;
            } else {
              savedAddress = "No address saved";
            }

            // Set default selection to saved address
            selectedLocation = savedAddress != "No address saved"
                ? "saved_address"
                : null;

            // Set default mandi selection
            selectedMandi = mandiName.isNotEmpty ? "saved_mandi" : null;
          });
        }
      } catch (e) {
        print('Error loading user profile: $e');
        setState(() {
          savedAddress = "Error loading address";
        });
      }
    }
  }

  @override
  void dispose() {
    cropController.dispose();
    quantityController.dispose();
    messageController.dispose();
    priceController.dispose();
    newAddressController.dispose();
    newMandiController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showNotAcceptingOrdersDialog(String cropName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Request Submitted",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF104f22),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Sorry, We are currently not taking orders for \"$cropName\". We will notify you as soon as we start taking orders.",
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Text(
              "खुशी, हम वर्तमान में \"$cropName\" के लिए ऑर्डर नहीं ले रहे हैं। जैसे ही हम ऑर्डर लेना शुरू करेंगे, हम आपको सूचित करेंगे।",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveCropRequest(cropName);
            },
            child: const Text("OK", style: TextStyle(color: Color(0xFF104f22))),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCropRequest(String cropName) async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('name') ?? 'Unknown';
      final userPhone = prefs.getString('phone') ?? '';
      final userState = prefs.getString('state') ?? '';
      final village = prefs.getString('village') ?? '';

      if (userId == null) {
        throw Exception("User not logged in");
      }

      // Determine delivery address
      String deliveryAddress = savedAddress;
      if (selectedLocation == "add_new" &&
          newAddressController.text.trim().isNotEmpty) {
        deliveryAddress = newAddressController.text.trim();
      }

      // Determine mandi name
      String mandiName = userProfile['mandiName']?.toString() ?? '';
      if (selectedMandi == "add_new_mandi" &&
          newMandiController.text.trim().isNotEmpty) {
        mandiName = newMandiController.text.trim();
      }

      // Save to database - using different path for trader requests
      final ref = FirebaseDatabase.instance
          .ref('requestednewcropbyvyapari/$userId')
          .push();

      await ref.set({
        "cropName": cropName,
        "userId": userId,
        "userName": userName,
        "userPhone": userPhone,
        "quantity": int.tryParse(quantityController.text.trim()) ?? 0,
        "unit": selectedUnit,
        "qualityGrades": selectedQualities.toList(),
        "expectedPrice": double.tryParse(priceController.text.trim()) ?? 0.0,
        "location": {
          "state": userState,
          "village": village,
          "deliveryAddress": deliveryAddress,
          "mandiName": mandiName,
        },
        "message": messageController.text.trim(),
        "status": "pending",
        "createdAt": ServerValue.timestamp,
        "updatedAt": ServerValue.timestamp,
      });

      if (mounted) {
        // Pop back to dashboard and navigate to History
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const VyapariDashboardScreenWithTab(initialTab: 2),
          ),
        );
      }
    } catch (e) {
      _showError("Failed to save request: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          /// 🌾 Top Background with Image
          Container(
            height: 220,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/cropnotlisted.jpg'),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          /// Dark overlay for better text visibility
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Back button row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: isLoading ? null : () {
                            print('Back button tapped in crop not listed screen');
                            Navigator.of(context).pop();
                          },
                          borderRadius: BorderRadius.circular(12),
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
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Request New Crop",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// White Card Container
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel("Crop Name *"),
                          TextFormField(
                            controller: cropController,
                            decoration: InputDecoration(
                              hintText: "Enter crop name",
                              filled: true,
                              fillColor: const Color(0xFFF3F3F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter crop name';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("Quantity"),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: quantityController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: "Enter quantity",
                                    filled: true,
                                    fillColor: const Color(0xFFF3F3F3),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: selectedUnit,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: const Color(0xFFF3F3F3),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 14,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  isExpanded: true,
                                  items: ["Kg", "Ton", "Quintal"]
                                      .map(
                                        (unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedUnit = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("Quality Grade (Select Multiple)"),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            children: ["A", "B", "C"]
                                .map(
                                  (grade) => FilterChip(
                                    label: Text(grade),
                                    selected: selectedQualities.contains(grade),
                                    onSelected: (selected) {
                                      setState(() {
                                        if (selected) {
                                          selectedQualities.add(grade);
                                        } else {
                                          selectedQualities.remove(grade);
                                        }
                                      });
                                    },
                                    selectedColor: const Color(0xFF104f22),
                                    labelStyle: TextStyle(
                                      color: selectedQualities.contains(grade)
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 20),

                          _buildLabel("Select Mandi *"),
                          const SizedBox(height: 8),

                          /// Mandi Dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedMandi,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF3F3F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.store,
                                color: Color(0xFF104f22),
                              ),
                            ),
                            hint: const Text("Select mandi"),
                            items: [
                              if (userProfile['mandiName'] != null &&
                                  userProfile['mandiName']
                                      .toString()
                                      .trim()
                                      .isNotEmpty)
                                DropdownMenuItem(
                                  value: "saved_mandi",
                                  child: Text(
                                    userProfile['mandiName'].toString(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const DropdownMenuItem(
                                value: "add_new_mandi",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_business,
                                      color: Color(0xFF104f22),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Add New Mandi",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF104f22),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedMandi = value;
                                showAddNewMandi = value == "add_new_mandi";
                              });
                            },
                          ),

                          /// New Mandi Input Field
                          if (showAddNewMandi) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: newMandiController,
                              decoration: InputDecoration(
                                hintText: "Enter mandi name...",
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.business_outlined,
                                  color: Color(0xFF104f22),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          _buildLabel("Delivery Location *"),
                          const SizedBox(height: 8),

                          /// Address Dropdown
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedLocation,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color(0xFFF3F3F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.location_on,
                                color: Color(0xFF104f22),
                              ),
                            ),
                            hint: const Text("Select delivery address"),
                            items: [
                              if (savedAddress != "No address saved" &&
                                  savedAddress != "Error loading address")
                                DropdownMenuItem(
                                  value: "saved_address",
                                  child: Text(
                                    "$savedAddress",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              const DropdownMenuItem(
                                value: "add_new",
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_location_alt,
                                      color: Color(0xFF104f22),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "Add New Address",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF104f22),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedLocation = value;
                                showAddNewAddress = value == "add_new";
                              });
                            },
                          ),

                          /// New Address Input Field
                          if (showAddNewAddress) ...[
                            const SizedBox(height: 12),
                            TextField(
                              controller: newAddressController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Enter your new delivery address...",
                                filled: true,
                                fillColor: const Color(0xFFF3F3F3),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon: const Icon(
                                  Icons.location_on_outlined,
                                  color: Color(0xFF104f22),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 18),

                          _buildLabel("Expected Price (₹/KG)"),
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: "Enter expected price",
                              filled: true,
                              fillColor: const Color(0xFFF3F3F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("Additional Message"),
                          TextFormField(
                            controller: messageController,
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: "Any additional information...",
                              filled: true,
                              fillColor: const Color(0xFFF3F3F3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF104f22),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                              child: const Text(
                                "Submit Request",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
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
                ),
              ],
            ),
          ),

          /// Upload Progress Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(
                        color: Color(0xFF104f22),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Submitting Request...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF104f22),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Please wait while we process your request...",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (cropController.text.trim().isEmpty) {
      _showError('Please enter crop name');
      return;
    }

    if (selectedLocation == null) {
      _showError('Please select a delivery address');
      return;
    }

    if (selectedMandi == null) {
      _showError('Please select a mandi');
      return;
    }

    if (selectedLocation == "add_new" &&
        newAddressController.text.trim().isEmpty) {
      _showError('Please enter your new delivery address');
      return;
    }

    if (selectedMandi == "add_new_mandi" &&
        newMandiController.text.trim().isEmpty) {
      _showError('Please enter the new mandi name');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final cropName = cropController.text.trim();
      _showNotAcceptingOrdersDialog(cropName);
    } catch (e) {
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
