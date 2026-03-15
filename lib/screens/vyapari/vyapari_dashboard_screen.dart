import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/main.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_detail_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_not_listed_screen.dart';

class VyapariDashboardScreen extends StatefulWidget {
  const VyapariDashboardScreen({super.key});

  @override
  State<VyapariDashboardScreen> createState() => _VyapariDashboardScreenState();
}

class _VyapariDashboardScreenState extends State<VyapariDashboardScreen> {
  String? selectedCrop;
  String? selectedLocation;
  String? selectedQuality;
  String traderName = "Vyapari";
  String traderPhone = "";
  String traderImage = "https://i.pravatar.cc/300";
  bool isGuest = false;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _loadTraderData();
  }

  Future<void> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
      if (isGuest) {
        traderName = "Guest User";
        traderPhone = "Guest Mode";
      }
    });
  }

  Future<void> _loadTraderData() async {
    if (isGuest) return; // Skip loading user data for guests

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        setState(() {
          traderName = data['name'] ?? 'Vyapari';
          traderPhone = data['phone'] ?? '';
          traderImage = data['profileImage'] ?? 'https://i.pravatar.cc/300';
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGuest ? "Exit Guest Mode" : "Logout"),
        content: Text(
          isGuest
              ? "Are you sure you want to exit guest mode?"
              : "Are you sure you want to logout?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthCheck()),
        (route) => false,
      );
    }
  }

  void _showGuestRestrictionDialog() {
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
              colors: [Colors.white, const Color(0xFF104f22).withOpacity(0.05)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF104f22).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_outline,
                  size: 40,
                  color: Color(0xFF104f22),
                ),
              ),

              const SizedBox(height: 20),

              /// Title
              const Text(
                "Feature Locked",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF104f22),
                ),
              ),

              const SizedBox(height: 12),

              /// Message
              const Text(
                "You're browsing in Guest Mode with limited access. To unlock all features including requesting crops, managing orders, and accessing your profile, please create an account.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              /// Benefits Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF104f22).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF104f22).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Unlock with Registration:",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF104f22),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF104f22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Request specific crops from farmers",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF104f22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Contact farmers directly",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Color(0xFF104f22),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Track orders & transaction history",
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              /// Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFF104f22),
                          width: 2,
                        ),
                        backgroundColor: Colors.transparent,
                        foregroundColor: const Color(0xFF104f22),
                        overlayColor: const Color(0xFF104f22),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            size: 18,
                            color: Color(0xFF104f22),
                          ),
                          const SizedBox(width: 6),
                          const Flexible(
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                color: Color(0xFF104f22),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthCheck()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF104f22),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
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

  List<Map<String, String>> get crops => [
    {"name": "Wheat", "image": "assets/images/login_bg.jpg"},
    {"name": "Maize", "image": "assets/images/maize.jpg"},
    {"name": "Rice", "image": "assets/images/rice.jpg"},
    {"name": "Potato", "image": "assets/images/potato.jpg"},
    {"name": "Soybean", "image": "assets/images/soybean.jpg"},
    {"name": "Green Gram", "image": "assets/images/greengram.jpg"},
    {"name": "Onion", "image": "assets/images/onion.jpg"},
    {"name": "Sugarcane", "image": "assets/images/sugarcane.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF104f22)),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(traderImage),
              ),
              accountName: Text(
                traderName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: Text(
                traderPhone.isEmpty ? "Loading..." : traderPhone,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text("Profile"),
              onTap: isGuest ? _showGuestRestrictionDialog : () {},
            ),
            ListTile(
              leading: const Icon(Icons.shopping_bag),
              title: const Text("My Orders"),
              onTap: isGuest ? _showGuestRestrictionDialog : () {},
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text("History"),
              onTap: isGuest ? _showGuestRestrictionDialog : () {},
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Settings"),
              onTap: isGuest ? _showGuestRestrictionDialog : () {},
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text("Help & Support"),
              onTap: () {},
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: Icon(
                isGuest ? Icons.exit_to_app : Icons.logout,
                color: Colors.red,
              ),
              title: Text(
                isGuest ? "Exit Guest Mode" : "Logout",
                style: const TextStyle(color: Colors.red),
              ),
              onTap: _logout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      body: Stack(
        children: [
          /// 🌾 Header Background
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

          /// Dark Overlay
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// Header with Menu Icon
                  Row(
                    children: [
                      Builder(
                        builder: (context) => Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                            icon: const Icon(
                              Icons.menu,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          "Welcome $traderName",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
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
                        _buildLabel("Crop Name"),
                        _buildCropDropdown(
                          value: selectedCrop,
                          hint: "Select Crop Name",
                          items: crops,
                          onChanged: (value) {
                            setState(() {
                              selectedCrop = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        _buildLabel("Location"),
                        _buildDropdown(
                          value: selectedLocation,
                          hint: "Select Location",
                          items: const ["Mumbai", "Delhi", "Lucknow"],
                          onChanged: (value) {
                            setState(() {
                              selectedLocation = value;
                            });
                          },
                        ),

                        const SizedBox(height: 15),

                        _buildLabel("Quality"),
                        _buildDropdown(
                          value: selectedQuality,
                          hint: "Select Quality",
                          items: const ["A", "B", "C"],
                          onChanged: (value) {
                            setState(() {
                              selectedQuality = value;
                            });
                          },
                        ),

                        const SizedBox(height: 25),

                        const Text(
                          "Crops",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 15),

                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: crops.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.9,
                              ),
                          itemBuilder: (context, index) {
                            return _buildCropCard(
                              crops[index]["name"]!,
                              crops[index]["image"]!,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          /// Floating Button at Bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isGuest
                      ? _showGuestRestrictionDialog
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CropNotListedScreen(),
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF104f22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    isGuest ? "Register to Request Crops" : "Crop not listed?",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
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

  Widget _buildCropDropdown({
    required String? value,
    required String hint,
    required List<Map<String, String>> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item["name"],
              child: Text(item["name"]!),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F3F3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      hint: Text(hint),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildCropCard(String name, String imagePath) {
    return GestureDetector(
      onTap: isGuest
          ? _showGuestRestrictionDialog
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      CropDetailScreen(cropName: name, imagePath: imagePath),
                ),
              );
            },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
              child: Image.asset(
                imagePath,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 10),

            /// Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
