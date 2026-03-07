import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddNewCropScreen extends StatefulWidget {
  const AddNewCropScreen({super.key});

  @override
  State<AddNewCropScreen> createState() => _AddNewCropScreenState();
}

class _AddNewCropScreenState extends State<AddNewCropScreen> {
  List<Map<String, dynamic>> allCrops = [];
  String? selectedCrop;
  String? selectedUnit = "Kg";
  Set<String> selectedQualities = {};
  
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final snapshot = await FirebaseDatabase.instance.ref('allcrops').once();
    if (snapshot.snapshot.value != null) {
      final data = snapshot.snapshot.value;
      setState(() {
        if (data is List) {
          allCrops = data.where((e) => e != null).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (data is Map) {
          allCrops = data.values.where((e) => e != null).map((e) => Map<String, dynamic>.from(e)).toList();
        }
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _submitCrop() async {
    if (selectedCrop == null ||
        quantityController.text.isEmpty ||
        selectedQualities.isEmpty ||
        priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');

      if (userId != null && userRole != null) {
        final collection = userRole == 'farmer' ? 'farmers' : 'traders';
        final ref = FirebaseDatabase.instance
            .ref('$collection/$userId/add_new_crop')
            .push();

        await ref.set({
          "cropName": selectedCrop,
          "quantity": quantityController.text,
          "unit": selectedUnit,
          "qualityGrades": selectedQualities.toList(),
          "imageUrl": "https://via.placeholder.com/300",
          "videoUrl": "https://via.placeholder.com/300",
          "expectedPrice": priceController.text,
          "createdAt": DateTime.now().toIso8601String(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Crop added successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => isLoading = false);
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
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/login_bg.jpg"),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          Positioned(
            top: 50, // Adjust this
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Add New Crop",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// White Card Container
                  isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF104f22),
                          ),
                        )
                      : Container(
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
                        _buildLabel("Crop Name"),
                        DropdownButtonFormField<String>(
                          value: selectedCrop,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFFF3F3F3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          hint: const Text("Select Crop"),
                          items: allCrops
                              .map((crop) => DropdownMenuItem<String>(
                                    value: crop['name'] as String,
                                    child: Text(crop['name'] as String),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCrop = value;
                            });
                          },
                        ),

                        const SizedBox(height: 18),

                        _buildLabel("Quantity"),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
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
                                    .map((unit) => DropdownMenuItem(
                                          value: unit,
                                          child: Text(unit),
                                        ))
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
                              .map((grade) => FilterChip(
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
                                  ))
                              .toList(),
                        ),

                        const SizedBox(height: 20),

                        _buildUploadButton(
                          "Upload / Capture Photo",
                          Icons.camera_alt,
                        ),

                        const SizedBox(height: 12),

                        _buildUploadButton(
                          "Upload / Capture Video",
                          Icons.videocam,
                        ),

                        const SizedBox(height: 18),

                        _buildLabel("Expected Price (₹)"),
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
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
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
    );
  }

  /// Label Widget
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  /// TextField Widget
  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

/// Upload Button
  Widget _buildUploadButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, color: const Color(0xFF104f22)),
        label: Text(text, style: const TextStyle(color: Color(0xFF104f22))),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: const BorderSide(color: Color(0xFF104f22)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
