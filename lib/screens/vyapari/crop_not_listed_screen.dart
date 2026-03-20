import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

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

  String? selectedLocation;
  String? selectedQuality;
  String? selectedUnit = "Kg";
  Set<String> selectedQualities = {};
  bool isLoading = false;
  bool isUploading = false;

  File? _cropImage;
  File? _cropVideo;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _videoController?.dispose();
    cropController.dispose();
    quantityController.dispose();
    messageController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 60,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large. Please select a smaller image.'),
            ),
          );
          return;
        }

        setState(() {
          _cropImage = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 1),
      );

      if (pickedFile != null && mounted) {
        final file = File(pickedFile.path);
        final size = await file.length();

        if (size > 50 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Video too large (max 50MB)')),
          );
          return;
        }

        setState(() {
          _cropVideo = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick video: ${e.toString()}')),
        );
      }
    }
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

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userName = prefs.getString('name') ?? 'Unknown';
      final userPhone = prefs.getString('phone') ?? '';

      if (userId == null) {
        throw Exception("User not logged in");
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      String? imageUrl;
      String? videoUrl;

      // Parallel uploads for better performance
      final uploadTasks = <Future>[];

      if (_cropImage != null) {
        final imageRef = FirebaseStorage.instance.ref(
          'crop_images/${userId}_$timestamp.jpg',
        );
        uploadTasks.add(
          imageRef.putFile(_cropImage!).then((_) => imageRef.getDownloadURL()),
        );
      }

      if (_cropVideo != null) {
        final videoRef = FirebaseStorage.instance.ref(
          'crop_videos/${userId}_$timestamp.mp4',
        );
        uploadTasks.add(
          videoRef.putFile(_cropVideo!).then((_) => videoRef.getDownloadURL()),
        );
      }

      final results = await Future.wait(uploadTasks);

      if (_cropImage != null && results.isNotEmpty) {
        imageUrl = results[0] as String;
      }
      if (_cropVideo != null && results.length > 1) {
        videoUrl = results[1] as String;
      } else if (_cropVideo != null &&
          _cropImage == null &&
          results.isNotEmpty) {
        videoUrl = results[0] as String;
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
        "imageUrl": imageUrl ?? "",
        "videoUrl": videoUrl ?? "",
        "expectedPrice": double.tryParse(priceController.text.trim()) ?? 0.0,
        "location": selectedLocation ?? "",
        "message": messageController.text.trim(),
        "status": "pending",
        "createdAt": ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your crop request has been submitted!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isUploading = false);
      }
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
                          child: _buildQuantityOption("1000", "Kg", Icons.monitor_weight),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuantityOption("10", "Quintal", Icons.inventory_2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuantityOption("1", "Ton", Icons.local_shipping),
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
                        side: BorderSide(color: Colors.grey.shade400, width: 1.5),
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final cropName = cropController.text.trim();

    // Validation
    if (cropName.isEmpty) {
      _showError('Please enter crop name');
      return;
    }

    if (quantityController.text.trim().isEmpty) {
      _showError('Please enter quantity');
      return;
    }

    // Validate minimum quantity
    if (!_validateMinimumQuantity()) {
      _showMinimumQuantityError();
      return;
    }

    if (selectedQualities.isEmpty) {
      _showError('Please select at least one quality grade');
      return;
    }

    if (selectedLocation == null) {
      _showError('Please select location');
      return;
    }

    if (messageController.text.trim().isEmpty) {
      _showError('Please enter message');
      return;
    }

    _showNotAcceptingOrdersDialog(cropName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),

      /// 🔥 Sticky Submit Button
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: isUploading ? null : _submitRequest,
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
                          onPressed: isUploading ? null : () => Navigator.pop(context),
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

                            _buildLabel("Quantity (Minimum 1000 Kg required)"),
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: _inputDecoration().copyWith(
                                      hintText: "Enter Quantity (min 1000)",
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? "This field is required"
                                            : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    value: selectedUnit,
                                    decoration: _inputDecoration(),
                                    isExpanded: true,
                                    items: ["Kg", "Ton", "Quintal"]
                                        .map(
                                          (unit) => DropdownMenuItem(
                                            value: unit,
                                            child: Text(
                                              unit,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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

                            _buildLabel("Quality (Select Multiple)"),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              children: ["A", "B", "C"].map((quality) {
                                final isSelected = selectedQualities.contains(quality);

                                return FilterChip(
                                  label: Text(quality),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedQualities.add(quality);
                                      } else {
                                        selectedQualities.remove(quality);
                                      }
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

                            _buildUploadButton(
                              "Upload / Capture Photo",
                              Icons.camera_alt,
                              onPressed: _showImageSourceDialog,
                              hasFile: _cropImage != null,
                            ),

                            const SizedBox(height: 12),

                            _buildUploadButton(
                              "Upload / Capture Video (Max 1 min)",
                              Icons.videocam,
                              onPressed: _showVideoSourceDialog,
                              hasFile: _cropVideo != null,
                            ),

                            const SizedBox(height: 18),

                            _buildLabel("Expected Price (₹/KG) - Optional"),
                            TextFormField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration().copyWith(
                                hintText: "Enter expected price",
                              ),
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

          /// Upload Progress Overlay
          if (isUploading)
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

  /// Upload Button
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
}