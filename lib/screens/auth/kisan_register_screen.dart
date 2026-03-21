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
  final TextEditingController pincodeController = TextEditingController();

  String stateValue = "";
  bool isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();
  bool acceptedTerms = false;

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

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.article_outlined, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Terms and Conditions",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        "1. Introduction",
                        "Welcome to Poketmandi. These Terms and Conditions govern your use of the Poketmandi mobile application and related services. By downloading, registering, or using the application, you agree to comply with these Terms.",
                      ),
                      _buildTermsSection(
                        "2. Definitions",
                        "Platform refers to the Poketmandi application and related services. User refers to any farmer, trader, buyer, or seller using the platform. Company refers to Poketmandi.com",
                      ),
                      _buildTermsSection(
                        "3. Eligibility",
                        "Users must be at least 18 years old and provide accurate information during registration. Users must comply with applicable laws related to agricultural trade in India.",
                      ),
                      _buildTermsSection(
                        "4. Account Registration",
                        "Users must keep their login credentials secure. Poketmandi is not responsible for losses resulting from unauthorized use of accounts.",
                      ),
                      _buildTermsSection(
                        "5. Platform Services",
                        "Poketmandi provides a digital marketplace connecting farmers, traders, and buyers. The platform enables listing of agricultural produce, price discovery, and communication between parties.",
                      ),
                      _buildTermsSection(
                        "6. Transactions Between Users",
                        "Transactions don't occur directly between users. Poketmandi acts as a technology facilitator but does not guarantee quality, quantity, or delivery unless explicitly stated.",
                      ),
                      _buildTermsSection(
                        "7. User Responsibilities",
                        "Users must not post misleading information, engage in fraud, or sell prohibited goods. Violations may result in suspension or termination of accounts.",
                      ),
                      _buildTermsSection(
                        "8. Payments and Fees",
                        "Certain services may include service fees, transaction charges, or subscription fees. These charges will be disclosed before confirmation.",
                      ),
                      _buildTermsSection(
                        "9. Intellectual Property",
                        "All platform content including design, software, and branding belongs to Poketmandi.",
                      ),
                      _buildTermsSection(
                        "10. Limitation of Liability",
                        "Poketmandi is not responsible for disputes, delivery delays, product quality issues, or financial losses resulting from user transactions.",
                      ),
                      _buildTermsSection(
                        "11. Governing Law",
                        "These Terms are governed by the laws of India. Any dispute should be settled within the jurisdiction of Ambikapur, Chattisgarh court.",
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(color: Color(0xFF104f22)),
                        ),
                        child: const Text(
                          "Close",
                          style: TextStyle(
                            color: Color(0xFF104f22),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            acceptedTerms = true;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF104f22),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          "Accept",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF104f22),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
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
    print("Pincode: ${pincodeController.text}");

    // Validate all required fields including profile image
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        phoneController.text.length != 10 ||
        villageController.text.isEmpty ||
        pincodeController.text.isEmpty ||
        pincodeController.text.length != 6 ||
        _profileImage == null ||
        !acceptedTerms) {
      print("Validation failed");

      String errorMessage = "Please fill all fields correctly";
      if (_profileImage == null) {
        errorMessage = "Profile photo is mandatory. Please upload your photo.";
      } else if (pincodeController.text.isEmpty ||
          pincodeController.text.length != 6) {
        errorMessage = "Please enter a valid 6-digit pincode.";
      } else if (!acceptedTerms) {
        errorMessage = "Please accept the Terms & Conditions to continue.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Upload profile image (now mandatory)
    setState(() => isLoading = true);
    String? imageUrl;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Image upload failed: $e"),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => isLoading = false);
      return;
    }
    setState(() => isLoading = false);

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
            "pincode": pincodeController.text,
            "state": stateValue.isEmpty ? "Uttar Pradesh" : stateValue,
            "country": "India",
            "profileImage": imageUrl!,
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

                        /// 📄 Main Registration Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              /// 🎯 Header Section
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF104f22),
                                      const Color(0xFF0d3f1c),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Image.asset(
                                        "assets/images/farmer2.png",
                                        height: 48,
                                        width: 48,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Kisan Registration",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Join our farming community",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              /// 📝 Form Content
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            _profileImage == null
                                                ? Colors.red.shade50
                                                : Colors.green.shade50,
                                            _profileImage == null
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _profileImage == null
                                              ? Colors.red.shade200
                                              : Colors.green.shade200,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (_profileImage == null
                                                        ? Colors.red
                                                        : Colors.green)
                                                    .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: _profileImage == null
                                                        ? Colors.red.shade300
                                                        : Colors.green.shade300,
                                                    width: 2,
                                                  ),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 32,
                                                  backgroundColor:
                                                      Colors.grey.shade200,
                                                  backgroundImage:
                                                      _profileImage != null
                                                      ? FileImage(
                                                          _profileImage!,
                                                        )
                                                      : null,
                                                  child: _profileImage == null
                                                      ? Icon(
                                                          Icons.person_add,
                                                          size: 32,
                                                          color: Colors
                                                              .grey
                                                              .shade600,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          _profileImage == null
                                                              ? Icons
                                                                    .warning_rounded
                                                              : Icons
                                                                    .check_circle_rounded,
                                                          size: 18,
                                                          color:
                                                              _profileImage ==
                                                                  null
                                                              ? Colors
                                                                    .red
                                                                    .shade600
                                                              : Colors
                                                                    .green
                                                                    .shade600,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            "Profile Photo",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  _profileImage ==
                                                                      null
                                                                  ? Colors
                                                                        .red
                                                                        .shade700
                                                                  : Colors
                                                                        .green
                                                                        .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          "*",
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: Colors
                                                                .red
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      _profileImage == null
                                                          ? "Photo is required for verification"
                                                          : "Photo uploaded successfully!",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                        height: 1.2,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: _showImageSourceDialog,
                                              icon: Icon(
                                                _profileImage == null
                                                    ? Icons.camera_alt_rounded
                                                    : Icons.edit_rounded,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              label: Text(
                                                _profileImage == null
                                                    ? "Upload Photo"
                                                    : "Change Photo",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF104f22,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    /// 📋 Personal Information Section
                                    _buildSectionHeader(
                                      "Personal Information",
                                      Icons.person_rounded,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildTextField(
                                      "Full Name *",
                                      controller: nameController,
                                      icon: Icons.person_rounded,
                                    ),

                                    const SizedBox(height: 16),

                                    _buildTextField(
                                      "Mobile Number *",
                                      isMobile: true,
                                      controller: phoneController,
                                      icon: Icons.phone_rounded,
                                    ),

                                    const SizedBox(height: 24),

                                    /// 📍 Location Information Section
                                    _buildSectionHeader(
                                      "Location Details",
                                      Icons.location_on_rounded,
                                    ),
                                    const SizedBox(height: 16),

                                    _buildTextField(
                                      "Village/Town *",
                                      controller: villageController,
                                      icon: Icons.location_city_rounded,
                                    ),

                                    const SizedBox(height: 16),

                                    _buildTextField(
                                      "Pincode *",
                                      isPincode: true,
                                      controller: pincodeController,
                                      icon: Icons.pin_drop_rounded,
                                    ),

                                    const SizedBox(height: 16),

                                    /// State Picker with Enhanced UI
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.map_rounded,
                                              size: 16,
                                              color: const Color(0xFF104f22),
                                            ),
                                            const SizedBox(width: 6),
                                            const Text(
                                              "State *",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: CSCPickerPlus(
                                            layout: Layout.vertical,
                                            showStates: true,
                                            showCities: false,
                                            flagState: CountryFlag.DISABLE,
                                            dropdownDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              color: Colors.white,
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                                width: 1.5,
                                              ),
                                            ),
                                            selectedItemStyle: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            dropdownItemStyle: const TextStyle(
                                              color: Colors.black87,
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
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 24),

                                    /// 👤 Profile Photo Section
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            userLatitude != null
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                            userLatitude != null
                                                ? Colors.green.shade100
                                                : Colors.orange.shade100,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: userLatitude != null
                                              ? Colors.green.shade200
                                              : Colors.orange.shade200,
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (userLatitude != null
                                                        ? Colors.green
                                                        : Colors.orange)
                                                    .withOpacity(0.1),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  12,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: userLatitude != null
                                                      ? Colors.green.shade100
                                                      : Colors.orange.shade100,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  userLatitude != null
                                                      ? Icons
                                                            .location_on_rounded
                                                      : Icons
                                                            .location_searching_rounded,
                                                  color: userLatitude != null
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                                  size: 24,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Icon(
                                                          userLatitude != null
                                                              ? Icons
                                                                    .check_circle_rounded
                                                              : Icons
                                                                    .info_rounded,
                                                          size: 18,
                                                          color:
                                                              userLatitude !=
                                                                  null
                                                              ? Colors
                                                                    .green
                                                                    .shade600
                                                              : Colors
                                                                    .orange
                                                                    .shade600,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            userLatitude != null
                                                                ? "Location Captured"
                                                                : "Capture Your Location",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  userLatitude !=
                                                                      null
                                                                  ? Colors
                                                                        .green
                                                                        .shade700
                                                                  : Colors
                                                                        .orange
                                                                        .shade700,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      userAddress ??
                                                          "Help buyers find you easily",
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors
                                                            .grey
                                                            .shade700,
                                                        height: 1.2,
                                                      ),
                                                      maxLines: 2,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: isLocationLoading
                                                  ? null
                                                  : _checkAndRequestLocation,
                                              icon: isLocationLoading
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor:
                                                            AlwaysStoppedAnimation<
                                                              Color
                                                            >(Colors.white),
                                                      ),
                                                    )
                                                  : Icon(
                                                      userLatitude != null
                                                          ? Icons
                                                                .refresh_rounded
                                                          : Icons
                                                                .my_location_rounded,
                                                      color: Colors.white,
                                                      size: 18,
                                                    ),
                                              label: Text(
                                                isLocationLoading
                                                    ? "Getting Location..."
                                                    : userLatitude != null
                                                    ? "Update Location"
                                                    : "Get My Location",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    userLatitude != null
                                                    ? Colors.green.shade600
                                                    : Colors.orange.shade600,
                                                disabledBackgroundColor:
                                                    Colors.grey.shade400,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    /// Terms & Conditions Checkbox
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            acceptedTerms ? Colors.green.shade50 : Colors.orange.shade50,
                                            acceptedTerms ? Colors.green.shade100 : Colors.orange.shade100,
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: acceptedTerms ? Colors.green.shade200 : Colors.orange.shade200,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    acceptedTerms = !acceptedTerms;
                                                  });
                                                },
                                                child: Container(
                                                  width: 24,
                                                  height: 24,
                                                  decoration: BoxDecoration(
                                                    color: acceptedTerms ? const Color(0xFF104f22) : Colors.white,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(
                                                      color: acceptedTerms ? const Color(0xFF104f22) : Colors.grey.shade400,
                                                      width: 2,
                                                    ),
                                                  ),
                                                  child: acceptedTerms
                                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                                      : null,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Wrap(
                                                      children: [
                                                        Text(
                                                          "I agree to the ",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.grey.shade700,
                                                          ),
                                                        ),
                                                        GestureDetector(
                                                          onTap: _showTermsAndConditions,
                                                          child: const Text(
                                                            "Terms & Conditions",
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Color(0xFF104f22),
                                                              fontWeight: FontWeight.w600,
                                                              decoration: TextDecoration.underline,
                                                            ),
                                                          ),
                                                        ),
                                                        Text(
                                                          " *",
                                                          style: TextStyle(
                                                            fontSize: 14,
                                                            color: Colors.red.shade600,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      acceptedTerms
                                                          ? "Thank you for accepting our terms"
                                                          : "Please read and accept to continue",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: _showTermsAndConditions,
                                              icon: const Icon(
                                                Icons.article_outlined,
                                                size: 16,
                                                color: Color(0xFF104f22),
                                              ),
                                              label: const Text(
                                                "Read Terms & Conditions",
                                                style: TextStyle(
                                                  color: Color(0xFF104f22),
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 10,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFF104f22),
                                                  width: 1.5,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                  ],
                                ),
                              ),

                              /// 📋 Action Section
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(20),
                                    bottomRight: Radius.circular(20),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    /// Register Button
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF104f22),
                                            Color(0xFF0d3f1c),
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF104f22,
                                            ).withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: isLoading
                                            ? null
                                            : sendToOtpScreen,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: isLoading
                                            ? Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: const [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(Colors.white),
                                                    ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text(
                                                    "Registering...",
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : const Text(
                                                "Register as Kisan",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    /// Terms & Conditions
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.blue.shade100,
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: Colors.blue.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "By registering, you agree to our Terms & Conditions and Privacy Policy",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade700,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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

  /// 🎨 Section Header Widget
  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF104f22).withOpacity(0.1),
            const Color(0xFF104f22).withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF104f22).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF104f22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF104f22),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 Enhanced TextField
  Widget _buildTextField(
    String label, {
    bool isMobile = false,
    bool isPincode = false,
    required TextEditingController controller,
    IconData? icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon ?? Icons.text_fields_rounded,
              size: 16,
              color: const Color(0xFF104f22),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                if (isMobile) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF104f22).withOpacity(0.1),
                          const Color(0xFF104f22).withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        "+91",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF104f22),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    height: 32,
                    width: 1.5,
                    color: Colors.grey.shade300,
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: (isMobile || isPincode)
                        ? TextInputType.phone
                        : TextInputType.text,
                    maxLength: isMobile
                        ? 10
                        : isPincode
                        ? 6
                        : null,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                    decoration: InputDecoration(
                      counterText: "",
                      hintText: isMobile
                          ? "Enter mobile number"
                          : isPincode
                          ? "Enter 6-digit pincode"
                          : "Enter ${label.replaceAll(' *', '').toLowerCase()}",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
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
