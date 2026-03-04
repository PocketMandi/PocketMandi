import 'package:flutter/material.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_detail_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_not_listed_screen.dart';

class VyapariDashboardScreen extends StatefulWidget {
  const VyapariDashboardScreen({super.key});

  @override
  State<VyapariDashboardScreen> createState() => _VyapariDashboardScreenState();
}

class _VyapariDashboardScreenState extends State<VyapariDashboardScreen> {
  String? selectedCrop;
  String? selectedLocation;
  String? selectedQuality;

  List<Map<String, String>> get crops => [
    {"name": "Wheat", "image": "assets/images/login_bg.jpg"},
    {"name": "Maize", "image": "assets/images/maize.jpg"},
    {"name": "Rice", "image": "assets/images/rice.jpg"},
    {"name": "Potato", "image": "assets/images/potato.jpg"},
    {"name": "Soybean", "image": "assets/images/soybean.jpg"},
    {"name": "Green Gram", "image": "assets/images/greengram.jpg"},
    {"name": "Onion", "image": "assets/images/onion.jpg"},
    {"name": "Sugarcane", "image": "assets/images/sugarcane.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          /// 🌾 Header Background
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

          /// Dark Overlay
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// Title
                  const Text(
                    "Welcome Vyapari",
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel("Crop Name"),
                        _buildCropDropdown(
                          value: selectedCrop,
                          hint: "Select Crop Name",
                          items: crops,
                          onChanged: (value) {
                            setState(() {
                              selectedCrop = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        _buildLabel("Location"),
                        _buildDropdown(
                          value: selectedLocation,
                          hint: "Select Location",
                          items: const ["Mumbai", "Delhi", "Lucknow"],
                          onChanged: (value) {
                            setState(() {
                              selectedLocation = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        _buildLabel("Quality"),
                        _buildDropdown(
                          value: selectedQuality,
                          hint: "Select Quality",
                          items: const ["A", "B", "C"],
                          onChanged: (value) {
                            setState(() {
                              selectedQuality = value;
                            });
                          },
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Crops",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: crops.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            return _buildCropCard(
                              crops[index]["name"]!,
                              crops[index]["image"]!,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// Floating Button at Bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CropNotListedScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104f22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    "Crop not listed?",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
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

  Widget _buildCropDropdown({
    required String? value,
    required String hint,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item["name"],
              child: Text(item["name"]!),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCropCard(String name, String imagePath) {
    return GestureDetector(
      onTap: () {
        // You can add navigation later
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CropDetailScreen(cropName: name, imagePath: imagePath),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            /// Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
