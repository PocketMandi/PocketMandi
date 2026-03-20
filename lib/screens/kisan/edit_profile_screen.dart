import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
<<<<<<< HEAD
=======
  final TextEditingController emailController = TextEditingController();
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
  final TextEditingController addressController = TextEditingController();
  final TextEditingController villageController = TextEditingController();
  final TextEditingController stateController = TextEditingController();
  final TextEditingController pincodeController = TextEditingController();
  
  // State variables
  bool isLoading = false;
  bool isUpdating = false;
  String? currentProfileImage;
  File? newProfileImage;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
<<<<<<< HEAD
=======
    emailController.dispose();
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
    addressController.dispose();
    villageController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id');
      
      if (userId != null) {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/$userId')
            .once();
            
        if (snapshot.snapshot.value != null) {
          final data = snapshot.snapshot.value as Map;
          
          setState(() {
            nameController.text = data['name'] ?? '';
            phoneController.text = data['phone'] ?? '';
<<<<<<< HEAD
=======
            emailController.text = data['email'] ?? '';
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
            addressController.text = data['address'] ?? '';
            villageController.text = data['village'] ?? '';
            stateController.text = data['state'] ?? '';
            pincodeController.text = data['pincode'] ?? '';
            currentProfileImage = data['profileImage'];
          });
        }
      }
    } catch (e) {
      _showError('Failed to load profile data: ${e.toString()}');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.camera);
                  },
                ),
                _buildImageOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _getImage(ImageSource.gallery);
                  },
                ),
                if (currentProfileImage != null || newProfileImage != null)
                  _buildImageOption(
                    icon: Icons.delete,
                    label: 'Remove',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        newProfileImage = null;
                        currentProfileImage = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF104f22)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color ?? const Color(0xFF104f22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color ?? const Color(0xFF104f22),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final compressedFile = await _compressImage(File(pickedFile.path));
        setState(() {
          newProfileImage = compressedFile;
        });
      }
    } catch (e) {
      _showError('Failed to pick image: ${e.toString()}');
    }
  }

  Future<File> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70,
        minWidth: 512,
        minHeight: 512,
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      return file;
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (userId == null) return;

    setState(() => isUpdating = true);

    try {
      String? profileImageUrl = currentProfileImage;

      // Upload new profile image if selected
      if (newProfileImage != null) {
        final imageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        await imageRef.putFile(newProfileImage!);
        profileImageUrl = await imageRef.getDownloadURL();
      }

      // Update user data in Firebase
      await FirebaseDatabase.instance.ref('users/$userId').update({
        'name': nameController.text.trim(),
<<<<<<< HEAD
=======
        'phone': phoneController.text.trim(),
        'email': emailController.text.trim(),
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
        'address': addressController.text.trim(),
        'village': villageController.text.trim(),
        'state': stateController.text.trim(),
        'pincode': pincodeController.text.trim(),
        'profileImage': profileImageUrl,
        'updatedAt': ServerValue.timestamp,
      });

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', nameController.text.trim());
<<<<<<< HEAD
=======
      await prefs.setString('phone', phoneController.text.trim());
      await prefs.setString('email', emailController.text.trim());
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
      await prefs.setString('address', addressController.text.trim());
      await prefs.setString('village', villageController.text.trim());
      await prefs.setString('state', stateController.text.trim());
      await prefs.setString('pincode', pincodeController.text.trim());
      if (profileImageUrl != null) {
        await prefs.setString('profileImage', profileImageUrl);
      }

      _showSuccess('Profile updated successfully!');
      Navigator.pop(context, true); // Return true to indicate success
    } catch (e) {
      _showError('Failed to update profile: ${e.toString()}');
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Header with gradient
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                // App bar
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: isUpdating ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Edit Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile Image Section
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: isUpdating ? null : _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: newProfileImage != null
                              ? Image.file(
                                  newProfileImage!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                )
                              : currentProfileImage != null
                                  ? CachedNetworkImage(
                                      imageUrl: currentProfileImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                      placeholder: (context, url) => Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF104f22),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF104f22),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Form Section
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF104f22),
                            ),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Personal Information'),
                                  const SizedBox(height: 16),
                                  
                                  _buildTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildTextField(
                                    controller: phoneController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
<<<<<<< HEAD
                                    enabled: false, // Make phone number read-only
=======
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      if (value.length != 10) {
                                        return 'Please enter a valid 10-digit phone number';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildTextField(
                                    controller: emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                          return 'Please enter a valid email address';
                                        }
                                      }
                                      return null;
                                    },
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
                                  ),
                                  
                                  const SizedBox(height: 24),
                                  
                                  _buildSectionTitle('Address Information'),
                                  const SizedBox(height: 16),
                                  
                                  _buildTextField(
                                    controller: addressController,
                                    label: 'Address',
                                    icon: Icons.home_outlined,
                                    maxLines: 2,
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildTextField(
                                          controller: villageController,
                                          label: 'Village/City',
                                          icon: Icons.location_city_outlined,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _buildTextField(
                                          controller: stateController,
                                          label: 'State',
                                          icon: Icons.map_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  _buildTextField(
                                    controller: pincodeController,
                                    label: 'Pincode',
                                    icon: Icons.pin_drop_outlined,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value != null && value.isNotEmpty) {
                                        if (value.length != 6) {
                                          return 'Please enter a valid 6-digit pincode';
                                        }
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 32),
                                  
                                  // Update Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isUpdating ? null : _updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF104f22),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 2,
                                      ),
                                      child: isUpdating
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text(
                                              'Update Profile',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
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
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF104f22),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
<<<<<<< HEAD
    bool enabled = true, // Add enabled parameter
=======
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
<<<<<<< HEAD
      enabled: enabled, // Use enabled parameter
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon, 
          color: enabled ? const Color(0xFF104f22) : Colors.grey,
        ),
=======
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF104f22)),
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
<<<<<<< HEAD
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
=======
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF104f22), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
<<<<<<< HEAD
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
=======
        fillColor: Colors.grey.shade50,
>>>>>>> 5f202c5fe2e97e0355a98ee87ddf929f8a026b67
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}