import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

class AddNewCropScreen extends StatefulWidget {
  const AddNewCropScreen({super.key});

  @override
  State<AddNewCropScreen> createState() => _AddNewCropScreenState();
}

class _AddNewCropScreenState extends State<AddNewCropScreen> {
  List<Map<String, dynamic>> allCrops = [];
  List<String> userListedCrops = [];
  String? selectedCrop;
  String? selectedUnit = "Kg";
  Set<String> selectedQualities = {};
  
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
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCrops();
    _loadUserListedCrops();
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

  Future<void> _loadUserListedCrops() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId/add_new_crop')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        setState(() {
          userListedCrops = data.values
              .map((e) => (e as Map)['cropName'] as String)
              .toList();
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _cropImage = File(pickedFile.path);
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video must be 1 minute or less")),
        );
        return;
      }
      
      setState(() {
        _cropVideo = file;
        _videoController?.dispose();
        _videoController = controller;
      });
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

    setState(() => isUploading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final userRole = prefs.getString('user_role');

      String? imageUrl;
      String? videoUrl;

      if (_cropImage != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('crop_images')
            .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await imageRef.putFile(_cropImage!);
        imageUrl = await imageRef.getDownloadURL();
      }

      if (_cropVideo != null) {
        final videoRef = FirebaseStorage.instance
            .ref()
            .child('crop_videos')
            .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.mp4');
        await videoRef.putFile(_cropVideo!);
        videoUrl = await videoRef.getDownloadURL();
      }

      if (userId != null && userRole != null) {
        final ref = FirebaseDatabase.instance
            .ref('users/$userId/add_new_crop')
            .push();

        await ref.set({
          "cropName": selectedCrop,
          "quantity": quantityController.text,
          "unit": selectedUnit,
          "qualityGrades": selectedQualities.toList(),
          "imageUrl": imageUrl ?? "https://via.placeholder.com/300",
          "videoUrl": videoUrl ?? "",
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

    setState(() => isUploading = false);
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
                onPressed: isUploading ? null : () => Navigator.pop(context),
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
                          isExpanded: true,
                          items: allCrops
                              .map((crop) {
                                final cropName = crop['name'] as String;
                                final isListed = userListedCrops.contains(cropName);
                                return DropdownMenuItem<String>(
                                  value: cropName,
                                  enabled: !isListed,
                                  child: Text(
                                    isListed ? "$cropName (Listed)" : cropName,
                                    style: TextStyle(
                                      color: isListed ? Colors.grey : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              })
                              .toList(),
                          onChanged: (value) {
                            if (value != null && userListedCrops.contains(value)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("You have already listed this crop!"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
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
  Widget _buildUploadButton(String text, IconData icon, {required VoidCallback onPressed, bool hasFile = false}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          side: BorderSide(color: hasFile ? Colors.green : const Color(0xFF104f22)),
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
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
