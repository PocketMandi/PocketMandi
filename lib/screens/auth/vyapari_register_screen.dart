import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:csc_picker_plus/csc_picker_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:poket_mandi/screens/auth/otp_verification_screen.dart';

class VyapariRegisterScreen extends StatefulWidget {
  const VyapariRegisterScreen({super.key});

  @override
  State<VyapariRegisterScreen> createState() => _VyapariRegisterScreenState();
}

class _VyapariRegisterScreenState extends State<VyapariRegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController mandiNameController = TextEditingController();

  String stateValue = "";
  String cityValue = "";
  bool isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

  void sendToOtpScreen() async {
    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        phoneController.text.length != 10 ||
        mandiNameController.text.isEmpty) {
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
            .child('${phoneController.text}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Image upload failed: $e")),
        );
        setState(() => isLoading = false);
        return;
      }
      setState(() => isLoading = false);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          phoneNumber: phoneController.text,
          userData: {
            "name": nameController.text,
            "phone": phoneController.text,
            "mandiName": mandiNameController.text,
            "city": cityValue.isEmpty ? "Not specified" : cityValue,
            "state": stateValue.isEmpty ? "Uttar Pradesh" : stateValue,
            "country": "India",
            "profileImage": imageUrl ?? "https://i.pravatar.cc/300",
          },
          isTrader: true,
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

                        /// 📄 Form Card
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
                              /// Trader Image + Title
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    "assets/images/vyapari.png", // add trader image
                                    height: 80,
                                  ),
                                  const SizedBox(width: 15),
                                  const Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(top: 20),
                                      child: Text(
                                        "I am Vyapari",
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

                              /// Upload Photo
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

                              /// Phone Number
                              _buildTextField(
                                "Phone Number *",
                                isMobile: true,
                                controller: phoneController,
                              ),

                              const SizedBox(height: 15),

                              /// Mandi Name (Textarea)
                              _buildTextArea(
                                "Mandi Name *",
                                controller: mandiNameController,
                              ),

                              const SizedBox(height: 15),

                              /// CSC Picker
                              CSCPickerPlus(
                                layout: Layout.vertical,
                                showStates: true,
                                showCities: true,
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
                                onCityChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      cityValue = value;
                                    });
                                  }
                                },
                              ),

                              const SizedBox(height: 15),

                              /// Location
                              Row(
                                children: const [
                                  Icon(Icons.location_on, color: Colors.green),
                                  SizedBox(width: 8),
                                  Text(
                                    "Google Location on Google map",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
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

  /// 🔹 Same TextField Method (Reuse from Kisan)
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
                  keyboardType:
                      isMobile ? TextInputType.phone : TextInputType.text,
                  maxLength: isMobile ? 10 : null,
                  decoration: InputDecoration(
                    counterText: "",
                    hintText: isMobile
                        ? "Enter mobile number"
                        : "Enter ${label.replaceAll(' *', '')}",
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

  Widget _buildTextArea(
    String label, {
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
          decoration: BoxDecoration(
            color: const Color(0xFFF2EEDC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: "Enter ${label.replaceAll(' *', '')}",
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

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
