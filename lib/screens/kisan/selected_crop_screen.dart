import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SelectedCropScreen extends StatefulWidget {
  final String cropId;
  final String cropName;
  final String cropImage;

  const SelectedCropScreen({
    super.key,
    required this.cropId,
    required this.cropName,
    required this.cropImage,
  });

  @override
  State<SelectedCropScreen> createState() => _SelectedCropScreenState();
}

class _SelectedCropScreenState extends State<SelectedCropScreen> {
  Set<String> selectedQualities = {};
  String? selectedUnit = "Kg";
  String? selectedLocation;
  DateTime? selectedDeliveryDate;
  bool isLoading = false;
  File? selectedImage;
  File? selectedVideo;
  VideoPlayerController? videoController;

  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController specialInstructionsController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> locations = ["Rajpur"];

  @override
  void dispose() {
    videoController?.dispose();
    quantityController.dispose();
    priceController.dispose();
    specialInstructionsController.dispose();
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
                image: widget.cropImage.startsWith('http')
                    ? NetworkImage(widget.cropImage) as ImageProvider
                    : AssetImage(widget.cropImage),
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

          /// 🔙 Back Button
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
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

                        _buildLabel("Location *"),
                        DropdownButtonFormField<String>(
                          value: selectedLocation,
                          decoration: InputDecoration(
                            hintText: "Select delivery location",
                            filled: true,
                            fillColor: const Color(0xFFF3F3F3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: locations
                              .map(
                                (location) => DropdownMenuItem(
                                  value: location,
                                  child: Text(location),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedLocation = value;
                            });
                          },
                        ),

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

                        const SizedBox(height: 20),

                        _buildUploadButton(
                          selectedImage != null
                              ? "✓ New Photo Selected"
                              : "Upload / Capture Photo",
                          Icons.camera_alt,
                          onPressed: _showImageSourceDialog,
                          hasFile: selectedImage != null,
                        ),

                        const SizedBox(height: 12),

                        _buildUploadButton(
                          selectedVideo != null
                              ? "✓ New Video Selected"
                              : "Upload / Capture Video (Max 1 min)",
                          Icons.videocam,
                          onPressed: _showVideoSourceDialog,
                          hasFile: selectedVideo != null,
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
                            hintText: "Any special handling, packaging, or delivery instructions...",
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
                        "We are adding your crop...",
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

  Widget _buildUploadButton(
    String text,
    IconData icon, {
    required VoidCallback onPressed,
    bool hasFile = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          side: BorderSide(
            color: hasFile ? Colors.green : const Color(0xFF104f22),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: hasFile ? Colors.green : const Color(0xFF104f22),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: hasFile ? Colors.green : const Color(0xFF104f22),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (hasFile)
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVideoSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Choose Video Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.videocam),
              title: const Text("Camera"),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library),
              title: const Text("Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickVideo(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Reduce quality for faster upload
      );

      if (pickedFile != null) {
        setState(() {
          isLoading = true;
        });

        // Compress image for faster upload
        final compressedFile = await _compressImage(File(pickedFile.path));

        setState(() {
          selectedImage = compressedFile;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
      }
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 70% quality - good balance
        minWidth: 1024, // Max width 1024px
        minHeight: 1024, // Max height 1024px
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      print('Compression error: $e');
      return file; // Return original if compression fails
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final pickedFile = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 1),
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      final controller = VideoPlayerController.file(file);
      await controller.initialize();

      final duration = controller.value.duration;

      if (duration.inSeconds > 60) {
        controller.dispose();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Video must be 1 minute or less")),
          );
        }
        return;
      }

      setState(() {
        selectedVideo = file;
        videoController?.dispose();
        videoController = controller;
      });
    }
  }

  Future<void> _submitCrop() async {
    if (quantityController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
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
        const SnackBar(content: Text('Please select a delivery location')),
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

      UploadTask? imageTask;
      UploadTask? videoTask;

      Reference? imageRef;
      Reference? videoRef;

      /// IMAGE UPLOAD
      if (selectedImage != null) {
        imageRef = FirebaseStorage.instance
            .ref()
            .child('crop_images')
            .child('${userId}_$timestamp.jpg');

        imageTask = imageRef.putFile(
          selectedImage!,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      }

      /// VIDEO UPLOAD
      if (selectedVideo != null) {
        videoRef = FirebaseStorage.instance
            .ref()
            .child('crop_videos')
            .child('${userId}_$timestamp.mp4');

        videoTask = videoRef.putFile(
          selectedVideo!,
          SettableMetadata(contentType: 'video/mp4'),
        );
      }

      /// RUN UPLOADS IN PARALLEL
      await Future.wait([
        if (imageTask != null) imageTask,
        if (videoTask != null) videoTask,
      ]);

      String? imageUrl;
      String? videoUrl;

      if (imageRef != null) {
        imageUrl = await imageRef.getDownloadURL();
      }

      if (videoRef != null) {
        videoUrl = await videoRef.getDownloadURL();
      }

      /// SAVE TO GLOBAL ADDEDCROPSBYKISSAAN COLLECTION
      final ref = FirebaseDatabase.instance
          .ref('addedcropsbykissan/$userId')
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
        "imageUrl": imageUrl ?? widget.cropImage,
        "videoUrl": videoUrl,
        "location": {
          "state": userState,
          "village": village,
          "deliveryLocation": selectedLocation,
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
            content: Text("Order placed successfully! Status: Pending"),
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
