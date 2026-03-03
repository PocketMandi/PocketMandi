import 'package:flutter/material.dart';

class KisanRegisterScreen extends StatelessWidget {
  const KisanRegisterScreen({super.key});

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
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {},
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
                              _buildTextField("Name *"),

                              const SizedBox(height: 15),

                              /// Mobile
                              _buildTextField(
                                "Mobile Number *",
                                isMobile: true,
                              ),

                              const SizedBox(height: 15),

                              /// Village
                              _buildTextField("Village *"),

                              const SizedBox(height: 15),

                              /// District
                              _buildDropdown("Select District"),

                              const SizedBox(height: 15),

                              /// State
                              _buildDropdown("Select State"),

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
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF104f22),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
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
  Widget _buildTextField(String label, {bool isMobile = false}) {
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
                  decoration: InputDecoration(
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
