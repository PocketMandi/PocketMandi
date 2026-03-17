import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:poket_mandi/screens/auth/otp_verification_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class KisanRegisterScreen extends StatefulWidget {
  const KisanRegisterScreen({super.key});

  @override
  State<KisanRegisterScreen> createState() => _KisanRegisterScreenState();
}

class _KisanRegisterScreenState extends State<KisanRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController villageController = TextEditingController();

  String stateValue = "";
  bool isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Location variables
  double? userLatitude;
  double? userLongitude;
  String? userAddress;
  bool isLocationLoading = false;

  @override
  void initState() {
    super.initState();
    // Automatically request location when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestLocation();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
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

  // Location functionality methods
  Future<void> _checkAndRequestLocation() async {
    try {
      setState(() => isLocationLoading = true);

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => isLocationLoading = false);
        _showLocationServiceDialog();
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => isLocationLoading = false);
          _showLocationPermissionDialog();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => isLocationLoading = false);
        _showLocationPermissionDialog();
        return;
      }

      // Get current position
      await Geolocator.getLastKnownPosition();
      Position? position = await Geolocator.getLastKnownPosition();

      position ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Location captured";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        address =
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
      }

      setState(() {
        userLatitude = position!.latitude;
        userLongitude = position!.longitude;
        userAddress = address;
        isLocationLoading = false;
      });

      _showLocationSuccessDialog();
    } catch (e) {
      setState(() => isLocationLoading = false);
      _showLocationErrorDialog(e.toString());
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.location_off, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Location Services Disabled",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "Please enable location services to help buyers find you easily and get better crop recommendations.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF085927),
              foregroundColor: Colors.white,
            ),
            child: const Text("Enable"),
          ),
        ],
      ),
    );
  }

  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.location_disabled, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                "Location Permission Required",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          "Location access helps buyers find you and improves your crop visibility. Please grant permission in settings.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF085927),
              foregroundColor: Colors.white,
            ),
            child: const Text("Settings"),
          ),
        ],
      ),
    );
  }

  void _showLocationSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text("Location Captured!", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          "Your location has been successfully captured: ${userAddress ?? 'Location saved'}",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF085927),
              foregroundColor: Colors.white,
            ),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showLocationErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.error, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Text("Location Error", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          "Failed to get location: ${error.contains('TimeoutException') ? 'Request timed out. Please try again.' : 'Please check your GPS and internet connection.'}",
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _checkAndRequestLocation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF085927),
              foregroundColor: Colors.white,
            ),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  void sendToOtpScreen() async {
    print("Register button clicked");
    print("Name: ${nameController.text}");
    print("Phone: ${phoneController.text}");
    print("Phone length: ${phoneController.text.length}");
    print("Village: ${villageController.text}");

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        phoneController.text.length != 10 ||
        villageController.text.isEmpty) {
      print("Validation failed");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields correctly")),
      );
      return;
    }

    String? imageUrl;
    if (_profileImage != null) {
      setState(() => isLoading = true);
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child(
              '${phoneController.text}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            );
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Image upload failed: $e")));
        setState(() => isLoading = false);
        return;
      }
      setState(() => isLoading = false);
    }

    print("Navigating to OTP screen");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: phoneController.text,
          userData: {
            "name": nameController.text,
            "phone": phoneController.text,
            "village": villageController.text,
            "state": stateValue.isEmpty ? "Uttar Pradesh" : stateValue,
            "country": "India",
            "profileImage": imageUrl ?? "https://i.pravatar.cc/300",
            "latitude": userLatitude?.toString() ?? "",
            "longitude": userLongitude?.toString() ?? "",
            "address": userAddress ?? "",
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌾 Background
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.jpg", fit: BoxFit.cover),
          ),

          /// 🌫 Overlay
          Container(color: Colors.black.withOpacity(0.35)),

          SafeArea(
            child: Column(
              children: [
                /// 🔙 Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
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
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        /// 🔰 Logo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ClipOval(
                              child: Image.asset(
                                "assets/images/logof.png",
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "PoketMandi",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// 📄 Form Card with Farmer Image
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Farmer Image + Title Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    "assets/images/farmer2.png",
                                    height: 80,
                                  ),
                                  const SizedBox(width: 15),
                                  const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 20),
                                      child: Text(
                                        "I am Kisan",
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF104f22),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// 👤 Upload Photo
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey,
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? const Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showImageSourceDialog,
                                      icon: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                      ),
                                      label: const Text(
                                        "Upload/Capture Photo",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF104f22,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),

                              /// Name
                              _buildTextField(
                                "Name *",
                                controller: nameController,
                              ),

                              const SizedBox(height: 15),

                              /// Mobile
                              _buildTextField(
                                "Mobile Number *",
                                isMobile: true,
                                controller: phoneController,
                              ),

                              const SizedBox(height: 15),

                              /// Village
                              _buildTextField(
                                "Village *",
                                controller: villageController,
                              ),

                              const SizedBox(height: 15),

                              /// CSC Picker
                              CSCPickerPlus(
                                layout: Layout.vertical,
                                showStates: true,
                                showCities: false,
                                flagState: CountryFlag.DISABLE,
                                dropdownDecoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: const Color(0xFFF2EEDC),
                                  border: Border.all(color: Colors.transparent),
                                ),
                                selectedItemStyle: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                                dropdownItemStyle: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                onCountryChanged: (value) {},
                                onStateChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      stateValue = value;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 15),

                              /// Location
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: userLatitude != null
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: userLatitude != null
                                        ? Colors.green.shade200
                                        : Colors.orange.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      userLatitude != null
                                          ? Icons.location_on
                                          : Icons.location_off,
                                      color: userLatitude != null
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            userLatitude != null
                                                ? "Location Captured"
                                                : "Capture Your Location",
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: userLatitude != null
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                          if (userAddress != null)
                                            Text(
                                              userAddress!,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          if (userLatitude == null)
                                            Text(
                                              "Help buyers find you easily",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    isLocationLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.green,
                                                  ),
                                            ),
                                          )
                                        : IconButton(
                                            onPressed: _checkAndRequestLocation,
                                            icon: Icon(
                                              userLatitude != null
                                                  ? Icons.refresh
                                                  : Icons.my_location,
                                              color: userLatitude != null
                                                  ? Colors.green
                                                  : Colors.orange,
                                              size: 20,
                                            ),
                                          ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// Register Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : sendToOtpScreen,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF104f22),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          "Register",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 10),

                              Center(
                                child: Text(
                                  "By registering, you agree to the Terms & Conditions",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
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

  /// 🔹 Reusable TextField
  Widget _buildTextField(
    String label, {
    bool isMobile = false,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEDC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              if (isMobile)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text(
                    "+91",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              if (isMobile)
                Container(height: 24, width: 1, color: Colors.black26),
              if (isMobile) const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: isMobile
                      ? TextInputType.phone
                      : TextInputType.text,
                  maxLength: isMobile ? 10 : null,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: isMobile
                        ? "Enter mobile number"
                        : "Enter ${label.replaceAll(' *', '')}",
                    hintStyle: const TextStyle(
                      color: Colors.black38,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 🔹 Reusable Dropdown UI (Static for now)
  Widget _buildDropdown(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEDC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Select",
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ],
    );
  }
}
