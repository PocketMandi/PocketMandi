import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CropDetailScreen extends StatefulWidget {
  final String cropName;
  final String imagePath;

  const CropDetailScreen({
    super.key,
    required this.cropName,
    required this.imagePath,
  });

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  Set<String> selectedQualities = {};
  String? selectedUnit = "Kg";
  String? selectedLocation;
  String? selectedMandi;
  DateTime? selectedDeliveryDate;
  bool isLoading = false;
  String savedAddress = "";
  bool showAddNewAddress = false;
  bool showAddNewMandi = false;
  Map<String, dynamic> userProfile = {};

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController specialInstructionsController =
      TextEditingController();
  final TextEditingController newAddressController = TextEditingController();
  final TextEditingController newMandiController = TextEditingController();

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

            print('Firebase data: $data'); // Debug log

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

            print('Complete address built: $savedAddress'); // Debug log

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
    quantityController.dispose();
    priceController.dispose();
    specialInstructionsController.dispose();
    newAddressController.dispose();
    newMandiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          /// 🌾 Top Background
          Container(
            height: 220,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: widget.imagePath.startsWith('http')
                    ? NetworkImage(widget.imagePath) as ImageProvider
                    : AssetImage(widget.imagePath),
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
                            print('Back button tapped in crop detail screen');
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
                  Text(
                    widget.cropName,
                    style: const TextStyle(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Quantity (Minimum 1000 Kg required)"),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: quantityController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "Enter quantity (min 1000)",
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

                        const SizedBox(height: 20),

                        _buildLabel("Required Delivery Date *"),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: const ColorScheme.light(
                                      primary: Color(0xFF104f22),
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              setState(() {
                                selectedDeliveryDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F3F3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedDeliveryDate == null
                                      ? "Select delivery date"
                                      : "${selectedDeliveryDate!.day}/${selectedDeliveryDate!.month}/${selectedDeliveryDate!.year}",
                                  style: TextStyle(
                                    color: selectedDeliveryDate == null
                                        ? Colors.grey[600]
                                        : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF104f22),
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        _buildLabel("Expected Price (₹/KG)"),
                        TextField(
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

                        _buildLabel("Special Instructions (Optional)"),
                        TextField(
                          controller: specialInstructionsController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText:
                                "Any special handling, packaging, or delivery instructions...",
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
                            onPressed: isLoading ? null : _submitCrop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104f22),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              "Submit",
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
                        "Hold on!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF104f22),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "We are processing your request...",
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

  bool _validateMinimumQuantity() {
    final quantityText = quantityController.text.trim();
    if (quantityText.isEmpty) return false;

    final quantity = double.tryParse(quantityText) ?? 0;
    final unit = selectedUnit ?? "Kg";

    // Convert to kg for validation
    double quantityInKg = quantity;
    switch (unit) {
      case "Ton":
        quantityInKg = quantity * 1000;
        break;
      case "Quintal":
        quantityInKg = quantity * 100;
        break;
      case "Kg":
      default:
        quantityInKg = quantity;
        break;
    }

    return quantityInKg >= 1000; // Minimum 1000 kg required
  }

  void _showMinimumQuantityError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Colors.red.shade50],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.scale_outlined,
                  size: 40,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Minimum Quantity Required",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "To ensure efficient processing and delivery, we require a minimum order quantity of 1000 Kg (1 Ton).",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Minimum acceptable quantities:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuantityOption(
                            "1000",
                            "Kg",
                            Icons.monitor_weight,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuantityOption(
                            "10",
                            "Quintal",
                            Icons.inventory_2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuantityOption(
                            "1",
                            "Ton",
                            Icons.local_shipping,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Colors.grey.shade400,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Got it",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityOption(String quantity, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 4),
          Text(
            quantity,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCrop() async {
    if (quantityController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // Validate minimum quantity
    if (!_validateMinimumQuantity()) {
      _showMinimumQuantityError();
      return;
    }

    if (selectedQualities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one quality grade'),
        ),
      );
      return;
    }

    if (selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery address')),
      );
      return;
    }

    if (selectedMandi == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a mandi')));
      return;
    }

    if (selectedLocation == "add_new" &&
        newAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your new delivery address')),
      );
      return;
    }

    if (selectedMandi == "add_new_mandi" &&
        newMandiController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the new mandi name')),
      );
      return;
    }

    if (selectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a required delivery date')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('name') ?? 'Unknown';
      final userPhone = prefs.getString('phone') ?? '';
      final userState = prefs.getString('state') ?? '';
      final village = prefs.getString('village') ?? '';

      if (userId == null) throw Exception("User not logged in");

      final timestamp = DateTime.now().millisecondsSinceEpoch;

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

      /// SAVE TO GLOBAL CROP REQUESTS COLLECTION (for traders)
      final ref = FirebaseDatabase.instance
          .ref('addedcropsbyvyapari/$userId')
          .push();
      final cropId = ref.key!;

      await ref.set({
        "cropId": cropId,
        "userId": userId,
        "userName": userName,
        "userPhone": userPhone,
        "cropType": widget.cropName,
        "quantity": int.parse(quantityController.text.trim()),
        "unit": selectedUnit,
        "pricePerUnit": double.parse(priceController.text.trim()),
        "qualityGrades": selectedQualities.toList(),
        "imageUrl": widget.imagePath,
        "location": {
          "state": userState,
          "village": village,
          "deliveryAddress": deliveryAddress,
          "mandiName": mandiName,
        },
        "requiredDeliveryDate": selectedDeliveryDate!.millisecondsSinceEpoch,
        "specialInstructions": specialInstructionsController.text.trim().isEmpty
            ? null
            : specialInstructionsController.text.trim(),
        "status": "pending",
        "createdAt": ServerValue.timestamp,
        "updatedAt": ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Crop request submitted successfully! Status: Pending",
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
