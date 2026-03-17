import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:poket_mandi/screens/kisan/my_order_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/main.dart';
import 'package:poket_mandi/screens/kisan/add_new_crop_screen.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KisanDashboardScreen extends StatefulWidget {
  const KisanDashboardScreen({super.key});

  @override
  State<KisanDashboardScreen> createState() => _KisanDashboardScreenState();
}

class _KisanDashboardScreenState extends State<KisanDashboardScreen> {
  String farmerName = "Kisan";
  String farmerPhone = "";
  String farmerImage = "https://i.pravatar.cc/300";
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;
  bool isGuest = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
    _loadCrops();
  }

  Future<void> _initializeUserData() async {
    await _checkGuestMode();
    await _loadFarmerData();
  }

  Future<void> _checkGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGuest = prefs.getBool('is_guest') ?? false;
      if (isGuest) {
        farmerName = "Guest User";
        farmerPhone = "Guest Mode";
      }
    });
  }

  Future<void> _loadFarmerData() async {
    if (isGuest) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId != null) {
      final snapshot = await FirebaseDatabase.instance
          .ref('users/$userId')
          .once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value as Map;
        setState(() {
          farmerName = data['name'] ?? 'Kisan';
          farmerPhone = data['phone'] ?? '';
          farmerImage = data['profileImage'] ?? 'https://i.pravatar.cc/300';
        });
      }
    }
  }

  Future<void> _loadCrops() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('allcrops').once();

      if (snapshot.snapshot.value != null) {
        final data = snapshot.snapshot.value;

        setState(() {
          if (data is Map) {
            crops = data.values
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else if (data is List) {
            crops = data
                .where((e) => e != null)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            crops = [];
          }
          isLoading = false;
        });
      } else {
        setState(() {
          crops = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        crops = [];
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load crops. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
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
              const Text(
                "Feature Locked",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF104f22),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "You're browsing in Guest Mode with limited access. To unlock all features including adding crops, managing orders, and accessing your profile, please create an account.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
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
                        side: const BorderSide(
                          color: Color(0xFF104f22),
                          width: 2,
                        ),
                      ),
                      child: const Text("Continue"),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Register Now",
                        style: TextStyle(color: Colors.white),
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

  void _onBottomNavTap(int index) {
    if (isGuest && index != 0) {
      _showGuestRestrictionDialog();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _selectedIndex == 0
          ? _buildHomeScreen()
          : _selectedIndex == 1
              ? _buildOrdersScreen()
              : _selectedIndex == 2
                  ? _buildHistoryScreen()
                  : _buildProfileScreen(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, "Home", 0),
                _buildNavItem(Icons.shopping_bag, "Orders", 1),
                _buildNavItem(Icons.history, "History", 2),
                _buildNavItem(Icons.person, "Profile", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onBottomNavTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF104f22).withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF104f22) : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF104f22) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 260,
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
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Spacer(),
                        ClipOval(
                          child: Image.asset(
                            "assets/images/logof.png",
                            width: 40,
                            height: 40,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "PoketMandi",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Image.asset("assets/images/farmer2.png", height: 120),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const SizedBox(height: 8),
                              const Text(
                                "Kisan Dashboard",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Welcome back, $farmerName Ji",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Available Crops",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF104f22),
                          ),
                        )
                      : crops.isEmpty
                          ? const Center(
                              child: Text(
                                "No crops available.\nPlease check back later!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : GridView.builder(
                              itemCount: crops.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1.6,
                              ),
                              itemBuilder: (context, index) {
                                return _buildCropCard(
                                  context,
                                  crops[index],
                                  index,
                                );
                              },
                            ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isGuest
                        ? _showGuestRestrictionDialog
                        : () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AddNewCropScreen(),
                              ),
                            );
                            _loadCrops();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF104f22),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isGuest ? "Register to Add Crops" : "Crop not listed?",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(
    BuildContext context,
    Map<String, dynamic> cropData,
    int index,
  ) {
    final cropId = cropData["id"];
    final name = cropData["name"] ?? "Unknown";
    final imagePath = cropData["image"] ?? "https://via.placeholder.com/300";

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: isGuest
          ? _showGuestRestrictionDialog
          : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectedCropScreen(
                    cropId: cropId?.toString() ?? 'crop_$index',
                    cropName: name,
                    cropImage: imagePath,
                  ),
                ),
              );
              if (result == true) {
                _loadCrops();
              }
            },
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: imagePath.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imagePath,
                        fit: BoxFit.cover,
                        memCacheWidth: 400,
                        memCacheHeight: 300,
                        placeholder: (context, url) => Container(
                          color: const Color(0xFF104f22).withOpacity(0.1),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF104f22),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: const Color(0xFF104f22).withOpacity(0.8),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.agriculture,
                                size: 40,
                                color: Colors.white,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Image unavailable',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        cacheHeight: 300,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF104f22).withOpacity(0.8),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.agriculture,
                                  size: 40,
                                  color: Colors.white,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Image not found',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              bottom: 10,
              left: 12,
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersScreen() {
    return const MyOrdersScreen();
  }

  Widget _buildHistoryScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            "History",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your transaction history will appear here",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: farmerImage.startsWith('http')
                            ? ClipOval(
                                child: CachedNetworkImage(
                                  imageUrl: farmerImage,
                                  fit: BoxFit.cover,
                                  width: 100,
                                  height: 100,
                                  placeholder: (context, url) =>
                                      const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF104f22),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Color(0xFF104f22),
                                  ),
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF104f22),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      farmerName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      farmerPhone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    if (isGuest)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, color: Colors.orange, size: 16),
                            SizedBox(width: 6),
                            Text(
                              "Guest Mode",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: "Edit Profile",
                  subtitle: "Update your personal information",
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.settings_outlined,
                  title: "Settings",
                  subtitle: "App preferences and configurations",
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.help_outline,
                  title: "Help & Support",
                  subtitle: "Get help and contact support",
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.info_outline,
                  title: "About",
                  subtitle: "App version and information",
                  onTap: () {},
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: Icon(
                      isGuest ? Icons.exit_to_app : Icons.logout,
                      color: Colors.white,
                    ),
                    label: Text(
                      isGuest ? "Exit Guest Mode" : "Logout",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF104f22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF104f22),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
