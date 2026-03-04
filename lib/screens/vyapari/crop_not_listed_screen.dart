import 'package:flutter/material.dart';
import 'package:poket_mandi/screens/vyapari/request_success_screen.dart';

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

  String? selectedLocation;
  String? selectedQuality;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),

      /// 🔥 Sticky Submit Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => RequestSuccessScreen()),
            );
            // if (_formKey.currentState!.validate()) {

            // }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF104f22),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Submit Request",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),

      body: Stack(
        children: [
          /// 🌿 Green Header with Image
          Container(
            height: 350,
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage("assets/images/cropnotlisted.jpg"),
                fit: BoxFit.fill,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          /// Dark Overlay
          Container(
            height: 350,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
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
                      const Expanded(
                        child: Text(
                          "Crop Not Listed?",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                /// 📋 Form
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 100),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF4F6F5),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 30),

                            /// Info Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF104f22,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF104f22),
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      "Can't find your crop? Let us know and we'll add it!",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 25),

                            _buildLabel("Crop Name"),
                            _buildTextField(
                              controller: cropController,
                              hint: "Enter Crop Name",
                            ),

                            const SizedBox(height: 18),

                            _buildLabel("Location"),
                            DropdownButtonFormField<String>(
                              value: selectedLocation,
                              decoration: _inputDecoration(),
                              hint: const Text("Select Location"),
                              items: const [
                                DropdownMenuItem(
                                  value: "Mumbai",
                                  child: Text("Mumbai"),
                                ),
                                DropdownMenuItem(
                                  value: "Delhi",
                                  child: Text("Delhi"),
                                ),
                                DropdownMenuItem(
                                  value: "Lucknow",
                                  child: Text("Lucknow"),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedLocation = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? "Please select location"
                                  : null,
                            ),

                            const SizedBox(height: 18),

                            _buildLabel("Quantity"),
                            _buildTextField(
                              controller: quantityController,
                              hint: "Enter Crop Quantity (kg)",
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

                            _buildLabel("Message"),
                            TextFormField(
                              controller: messageController,
                              maxLines: 4,
                              decoration: _inputDecoration().copyWith(
                                hintText: "Type your request details...",
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? "Please enter message"
                                  : null,
                            ),

                            const SizedBox(height: 20),
                          ],
                        ),
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

  /// 🔹 Input Decoration
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
