import 'package:flutter/material.dart';

class SelectedCropScreen extends StatefulWidget {
  final String cropName;
  final String imagePath;

  const SelectedCropScreen({
    super.key,
    required this.cropName,
    required this.imagePath,
  });

  @override
  State<SelectedCropScreen> createState() => _SelectedCropScreenState();
}

class _SelectedCropScreenState extends State<SelectedCropScreen> {
  String selectedQuality = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// Background
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.jpg", fit: BoxFit.cover),
          ),

          Container(color: Colors.black.withOpacity(0.3)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Back
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),

                  const SizedBox(height: 10),

                  /// Crop Title
                  Center(
                    child: Text(
                      widget.cropName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  /// Crop Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(widget.imagePath),
                  ),

                  const SizedBox(height: 20),

                  _buildLabel("Quantity *"),
                  _buildTextField("Enter quantity"),

                  const SizedBox(height: 15),

                  _buildLabel("Quality *"),
                  Row(
                    children: ["A", "B", "C"].map((grade) {
                      return Row(
                        children: [
                          Checkbox(
                            value: selectedQuality == grade,
                            onChanged: (_) {
                              setState(() {
                                selectedQuality = grade;
                              });
                            },
                          ),
                          Text(
                            grade,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                        ],
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 15),

                  _buildUploadButton("Upload/Capture Photo", Icons.camera_alt),
                  const SizedBox(height: 10),
                  _buildUploadButton("Upload/Capture Video", Icons.videocam),

                  const SizedBox(height: 15),

                  _buildLabel("Expected Price"),
                  _buildTextField("Enter expected price"),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF104f22),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Submit"),
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, color: Colors.white),
    );
  }

  Widget _buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E4A32),
        ),
      ),
    );
  }
}
