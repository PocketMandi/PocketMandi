import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class SelectedCropScreen extends StatefulWidget {
  final Map<String, dynamic> cropData;
  final String cropId;

  const SelectedCropScreen({
    super.key,
    required this.cropData,
    required this.cropId,
  });

  @override
  State<SelectedCropScreen> createState() => _SelectedCropScreenState();
}

class _SelectedCropScreenState extends State<SelectedCropScreen> {
  List<String> selectedQualities = ["A"]; // Changed to List for multiple selection
  bool isLoading = false;
  File? selectedImage;
  File? selectedVideo;
  VideoPlayerController? videoController;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _prefillData();
  }

  void _prefillData() {
    quantityController.text = widget.cropData['quantity']?.toString() ?? '';
    priceController.text = widget.cropData['expectedPrice']?.toString() ?? '';
    
    // Handle multiple qualities from Firebase
    if (widget.cropData['qualityGrades'] != null) {
      if (widget.cropData['qualityGrades'] is List) {
        selectedQualities = List<String>.from(widget.cropData['qualityGrades']);
      } else if (widget.cropData['qualityGrades'] is Map) {
        // Handle Firebase indexed format like {0: "A", 1: "B"}
        final qualityMap = widget.cropData['qualityGrades'] as Map;
        selectedQualities = qualityMap.values.cast<String>().toList();
      } else if (widget.cropData['qualityGrades'] is String) {
        selectedQualities = [widget.cropData['qualityGrades']];
      }
    } else if (widget.cropData['quality'] != null) {
      // Fallback to old 'quality' field
      if (widget.cropData['quality'] is List) {
        selectedQualities = List<String>.from(widget.cropData['quality']);
      } else if (widget.cropData['quality'] is String) {
        selectedQualities = [widget.cropData['quality']];
      }
    }
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: Stack(
        children: [
          /// 🌾 TOP HEADER IMAGE
          Container(
            height: 260,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: selectedImage != null
                    ? FileImage(selectedImage!)
                    : (widget.cropData['imageUrl'] != null
                        ? NetworkImage(widget.cropData['imageUrl'])
                        : const AssetImage('assets/images/default_crop.png')) as ImageProvider,
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          /// Dark overlay
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.35),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          /// 🔙 Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
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

          /// Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 80),

                  /// Crop Title
                  Text(
                    widget.cropData['cropName'] ?? 'Edit Crop',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// White Form Card
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
                        _buildLabel("Quantity"),
                        _buildTextField(quantityController, "Enter quantity"),

                        const SizedBox(height: 20),

                        _buildLabel("Quality Grade"),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            "A",
                            "B",
                            "C",
                          ].map((grade) => _buildQualityChip(grade)).toList(),
                        ),

                        // Show selected qualities
                        if (selectedQualities.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              "Selected: ${selectedQualities.join(', ')}",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF104f22),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        const SizedBox(height: 20),

                        _buildUploadButton(
                          selectedImage != null 
                              ? "✓ New Photo Selected" 
                              : (widget.cropData['imageUrl'] != null 
                                  ? "✓ Photo Uploaded - Change?" 
                                  : "Upload / Capture Photo"),
                          Icons.camera_alt,
                          () => _pickImage(),
                        ),

                        const SizedBox(height: 12),

                        _buildUploadButton(
                          selectedVideo != null 
                              ? "✓ New Video Selected" 
                              : (widget.cropData['videoUrl'] != null 
                                  ? "✓ Video Uploaded - Change?" 
                                  : "Upload / Capture Video"),
                          Icons.videocam,
                          () => _pickVideo(),
                        ),

                        const SizedBox(height: 20),

                        _buildLabel("Expected Price"),
                        _buildTextField(
                          priceController,
                          "Enter expected price",
                        ),

                        const SizedBox(height: 25),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _updateCrop,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF104f22),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text(
                                    "Update Crop",
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

                  const SizedBox(height: 30),
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
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    );
  }

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

  Widget _buildQualityChip(String grade) {
    bool isSelected = selectedQualities.contains(grade);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedQualities.remove(grade);
          } else {
            selectedQualities.add(grade);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF104f22) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          grade,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton(String text, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      
      if (controller.value.duration.inSeconds > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video must be 1 minute or less')),
        );
        controller.dispose();
        return;
      }
      
      setState(() {
        selectedVideo = file;
        videoController?.dispose();
        videoController = controller;
      });
    }
  }

  Future<void> _updateCrop() async {
    if (quantityController.text.isEmpty || priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (selectedQualities.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one quality grade')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? imageUrl = widget.cropData['imageUrl'];
      String? videoUrl = widget.cropData['videoUrl'];

      // Upload new image if selected
      if (selectedImage != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('crop_images')
            .child('${user.uid}_${widget.cropId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putFile(selectedImage!);
        imageUrl = await imageRef.getDownloadURL();
      }

      // Upload new video if selected
      if (selectedVideo != null) {
        final videoRef = FirebaseStorage.instance
            .ref()
            .child('crop_videos')
            .child('${user.uid}_${widget.cropId}_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await videoRef.putFile(selectedVideo!);
        videoUrl = await videoRef.getDownloadURL();
      }

      // Update crop data
      final cropRef = FirebaseDatabase.instance
          .ref()
          .child('crops')
          .child(widget.cropId);

      await cropRef.update({
        'quantity': quantityController.text,
        'qualityGrades': selectedQualities, // Save as array with correct field name
        'expectedPrice': priceController.text,
        'imageUrl': imageUrl,
        'videoUrl': videoUrl,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Crop updated successfully!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating crop: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
