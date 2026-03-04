import 'package:flutter/material.dart';

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
  final _formKey = GlobalKey<FormState>();

  String? selectedQuality;
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  String? selectedState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),

      /// 🔥 Bottom Submit Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              // Submit logic here
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF104f22),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Submit",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      body: Stack(
        children: [
          /// 🌿 Green Curved Header
          Container(
            height: 180,
            decoration: const BoxDecoration(
              color: Color(0xFF104f22),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                /// 🔙 Back + Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        widget.cropName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 🌾 Floating Crop Image Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      widget.imagePath,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                /// 📋 Form Section
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          _buildLabel("Quantity"),
                          _buildTextField(
                            controller: quantityController,
                            hint: "Enter Quantity (in kg)",
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("Quality"),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            children: ["A", "B", "C"].map((quality) {
                              final isSelected = selectedQuality == quality;

                              return ChoiceChip(
                                label: Text(quality),
                                selected: isSelected,
                                onSelected: (_) {
                                  setState(() {
                                    selectedQuality = quality;
                                  });
                                },
                                selectedColor: const Color(0xFF104f22),
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("District"),
                          _buildTextField(
                            controller: districtController,
                            hint: "Enter District",
                          ),

                          const SizedBox(height: 18),

                          _buildLabel("State"),
                          DropdownButtonFormField<String>(
                            value: selectedState,
                            decoration: _inputDecoration(),
                            hint: const Text("Select State"),
                            items: const [
                              DropdownMenuItem(
                                value: "Uttar Pradesh",
                                child: Text("Uttar Pradesh"),
                              ),
                              DropdownMenuItem(
                                value: "Maharashtra",
                                child: Text("Maharashtra"),
                              ),
                              DropdownMenuItem(
                                value: "Delhi",
                                child: Text("Delhi"),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedState = value;
                              });
                            },
                            validator: (value) =>
                                value == null ? "Please select state" : null,
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Label
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

  /// 🔹 TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextFormField(
      controller: controller,
      decoration: _inputDecoration().copyWith(hintText: hint),
      validator: (value) =>
          value == null || value.isEmpty ? "This field is required" : null,
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.shade200,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
