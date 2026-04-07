import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:poket_mandi/services/notification_service.dart';
import 'package:poket_mandi/services/upload_queue_service.dart';
import 'package:poket_mandi/screens/kisan/my_order_screen.dart';
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
  final TextEditingController specialInstructionsController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<String> locations = ["Rajpur"];

  @override
  void dispose() {
    videoController?.dispose();
    quantityController.dispose();
    priceController.dispose();
    specialInstructionsController.dispose();
    VideoCompress.cancelCompression();
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

          SafeArea(
            child: Column(
              children: [
                /// 🔙 Back Button Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                print(
                                  "Back button tapped from SafeArea!",
                                ); // Debug print
                                Navigator.of(context).pop();
                              },
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
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              _buildLabel(
                                "Quantity (Minimum 1000 Kg required)",
                              ),
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
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 14,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                        selected: selectedQualities.contains(
                                          grade,
                                        ),
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
                                          color:
                                              selectedQualities.contains(grade)
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
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
        quality: 50,
        minWidth: 800,
        minHeight: 800,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      print('Compression error: $e');
      return file;
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        setState(() {
          selectedVideo = file;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Video selected'),
            duration: Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking video: $e')),
        );
      }
    }
  }

  Future<File> _compressVideo(File file) async {
    try {
      final info = await VideoCompress.compressVideo(
        file.path,
        quality: VideoQuality.LowQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info != null && info.file != null) {
        return info.file!;
      }
      return file;
    } catch (e) {
      print('Video compression error: $e');
      return file;
    }
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

    if (!_validateMinimumQuantity()) {
      _showMinimumQuantityError();
      return;
    }

    if (selectedQualities.isEmpty ||
        selectedLocation == null ||
        selectedDeliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('name') ?? 'Unknown';
      final userPhone = prefs.getString('phone') ?? '';
      final userState = prefs.getString('state') ?? '';
      final village = prefs.getString('village') ?? '';

      if (userId == null) throw Exception("User not logged in");

      final ref = FirebaseDatabase.instance
          .ref('addedcropsbykissan/$userId')
          .push();

      final cropId = ref.key!;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      /// ✅ STEP 1: SAVE DATA INSTANTLY (NO WAIT)
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
        "imageUrl": selectedImage != null ? null : widget.cropImage,
        "videoUrl": null,
        "uploadStatus": (selectedImage != null || selectedVideo != null) ? "uploading" : "completed",
        "location": {
          "state": userState,
          "village": village,
          "deliveryLocation": selectedLocation,
        },
        "requiredDeliveryDate":
            selectedDeliveryDate!.millisecondsSinceEpoch,
        "specialInstructions":
            specialInstructionsController.text.trim().isEmpty
                ? null
                : specialInstructionsController.text.trim(),
        "status": "pending",
        "createdAt": ServerValue.timestamp,
        "updatedAt": ServerValue.timestamp,
      });

      /// ✅ STEP 2: NAVIGATE IMMEDIATELY (FAST UX)
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MyOrdersScreen(initialTab: 0),
          ),
        );
      }

      /// ✅ STEP 3: ADD TO UPLOAD QUEUE
      if (selectedImage != null || selectedVideo != null) {
        await UploadQueueService.addToQueue(
          userId: userId,
          recordId: cropId,
          recordPath: 'addedcropsbykissan/$userId/$cropId',
          timestamp: timestamp,
          imagePath: selectedImage?.path,
          videoPath: selectedVideo?.path,
          userName: userName,
          cropName: widget.cropName,
          notificationType: 'crop_order',
        );

        UploadQueueService.processPendingUploads();
      } else {
        await NotificationService.sendNotificationToAdmins(
          title: 'New Crop Order',
          body: '$userName ordered ${widget.cropName}',
          type: 'crop_order',
          data: {"orderId": cropId},
        );
      }

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _uploadMediaInBackground(
    String userId,
    String cropId,
    int timestamp,
    DatabaseReference ref,
    String userName,
  ) async {
    try {
      String? imageUrl;
      String? videoUrl;

      /// IMAGE
      if (selectedImage != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('crop_images/${userId}_$timestamp.jpg');

        await imageRef.putFile(selectedImage!).timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('Image upload timeout'),
        );
        imageUrl = await imageRef.getDownloadURL();
      }

      /// VIDEO - COMPRESS THEN UPLOAD
      if (selectedVideo != null) {
        File videoToUpload = selectedVideo!;
        
        try {
          final compressed = await _compressVideo(selectedVideo!);
          videoToUpload = compressed;
        } catch (e) {
          print('Compression failed, uploading original: $e');
        }

        final videoRef = FirebaseStorage.instance
            .ref()
            .child('crop_videos/${userId}_$timestamp.mp4');

        await videoRef.putFile(videoToUpload).timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('Video upload timeout'),
        );
        videoUrl = await videoRef.getDownloadURL();
      }

      /// UPDATE DB AFTER UPLOAD
      await ref.update({
        if (imageUrl != null) "imageUrl": imageUrl,
        if (videoUrl != null) "videoUrl": videoUrl,
        "uploadStatus": "completed",
        "updatedAt": ServerValue.timestamp,
      });

      /// SEND NOTIFICATION AFTER SUCCESS
      await NotificationService.sendNotificationToAdmins(
        title: 'New Crop Order',
        body: '$userName ordered ${widget.cropName}',
        type: 'crop_order',
        data: {"orderId": cropId},
      );

    } catch (e) {
      print('Upload failed: $e');
      await ref.update({
        "uploadStatus": "failed",
        "uploadError": e.toString(),
        "updatedAt": ServerValue.timestamp,
      });
    }
  }
}
