import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/services/notification_service.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

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
  bool showManualEntry = false;

  final TextEditingController cropNameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  bool isLoading = true;
  bool isUploading = false;

  File? _cropImage;
  File? _cropVideo;
  VideoPlayerController? _videoController;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _videoController?.dispose();
    cropNameController.dispose();
    quantityController.dispose();
    priceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('allcrops').get();

      if (!snapshot.exists) {
        setState(() => isLoading = false);
        return;
      }

      final data = snapshot.value;
      List<Map<String, dynamic>> crops = [];

      if (data is List) {
        crops = data
            .where((e) => e != null)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } else if (data is Map) {
        crops = data.values
            .where((e) => e != null)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }

      if (mounted) {
        setState(() {
          allCrops = crops;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load crops: ${e.toString()}')),
        );
      }
    }
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

  List<DropdownMenuItem<String>> _buildDropdownItems() {
    if (allCrops.isEmpty) {
      return [
        const DropdownMenuItem<String>(
          value: "Not Listed",
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  "Not Listed - Add Custom Crop",
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return [
      ...allCrops.map((crop) {
        final cropName = crop['name'] as String? ?? 'Unknown';
        return DropdownMenuItem<String>(
          value: cropName,
          child: Text(cropName, overflow: TextOverflow.ellipsis),
        );
      }),
      const DropdownMenuItem<String>(
        value: "Not Listed",
        child: Row(
          children: [
            Icon(Icons.add_circle_outline, color: Colors.orange, size: 18),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                "Not Listed - Add Custom Crop",
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ];
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
    final cropName = showManualEntry
        ? cropNameController.text.trim()
        : selectedCrop;

    // Validation
    if (selectedCrop == null) {
      _showError('Please select a crop');
      return;
    }

    if (showManualEntry && (cropName?.isEmpty ?? true)) {
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

    if (priceController.text.trim().isEmpty) {
      _showError('Please enter expected price');
      return;
    }

    _showNotAcceptingOrdersDialog(cropName!);
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

      // Save to database
      final ref = FirebaseDatabase.instance
          .ref('requestednewcrop/$userId')
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
        "status": "pending",
        "createdAt": ServerValue.timestamp,
      });

      // Send notification to all admins
      await NotificationService.sendNotificationToAdmins(
        title: 'New Crop Request',
        body: '$userName has requested $cropName (${quantityController.text} $selectedUnit)',
        data: {
          'type': 'crop_request',
          'cropName': cropName,
          'userId': userId,
          'requestId': ref.key,
        },
      );

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

          SafeArea(
            child: Column(
              children: [
                /// 🔙 Back Button Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : () {
                                print(
                                  "Back button tapped from AddNewCrop!",
                                ); // Debug print
                                Navigator.of(context).pop();
                              },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF104f22),
                            size: 24,
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
                                    const SizedBox(height: 4),
                                    Text(
                                      "Select from available crops or choose 'Not Listed' for manual entry",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      value: selectedCrop,
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: const Color(0xFFF3F3F3),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                      hint: const Text("Select Crop"),
                                      isExpanded: true,
                                      items: _buildDropdownItems(),
                                      onChanged: (value) {
                                        setState(() {
                                          selectedCrop = value;
                                          showManualEntry =
                                              value == "Not Listed";
                                          if (!showManualEntry) {
                                            cropNameController.clear();
                                          }
                                        });
                                      },
                                    ),

                                    if (showManualEntry) ...[
                                      const SizedBox(height: 12),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(
                                              0.3,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.orange,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                "Enter the name of the crop you want to add",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.orange[800],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildLabel("Enter Crop Name"),
                                      TextField(
                                        controller: cropNameController,
                                        decoration: InputDecoration(
                                          hintText:
                                              "e.g., Organic Tomato, Basmati Rice",
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
                                    ],

                                    const SizedBox(height: 18),

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
                                              hintText:
                                                  "Enter quantity (min 1000)",
                                              filled: true,
                                              fillColor: const Color(
                                                0xFFF3F3F3,
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                              fillColor: const Color(
                                                0xFFF3F3F3,
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 14,
                                                  ),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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

                                    _buildLabel(
                                      "Quality Grade (Select Multiple)",
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 10,
                                      children: ["A", "B", "C"]
                                          .map(
                                            (grade) => FilterChip(
                                              label: Text(grade),
                                              selected: selectedQualities
                                                  .contains(grade),
                                              onSelected: (selected) {
                                                setState(() {
                                                  if (selected) {
                                                    selectedQualities.add(
                                                      grade,
                                                    );
                                                  } else {
                                                    selectedQualities.remove(
                                                      grade,
                                                    );
                                                  }
                                                });
                                              },
                                              selectedColor: const Color(
                                                0xFF104f22,
                                              ),
                                              labelStyle: TextStyle(
                                                color:
                                                    selectedQualities.contains(
                                                      grade,
                                                    )
                                                    ? Colors.white
                                                    : Colors.black,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),

                                    const SizedBox(height: 20),

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

                                    _buildLabel("Expected Price (₹/KG)"),
                                    TextField(
                                      controller: priceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: "Enter expected price",
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

                                    const SizedBox(height: 25),

                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : _submitCrop,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF104f22,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
