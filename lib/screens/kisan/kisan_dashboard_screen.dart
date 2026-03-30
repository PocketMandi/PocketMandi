import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:poket_mandi/screens/kisan/my_order_screen.dart';
import 'package:poket_mandi/screens/kisan/edit_profile_screen.dart';
import 'package:poket_mandi/screens/common/about_screen.dart';
import 'package:poket_mandi/screens/common/policies_screen.dart';
import 'package:poket_mandi/screens/common/notifications_screen.dart';
import 'package:poket_mandi/screens/common/user_notifications_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/auth/landing_screen.dart';
import 'package:poket_mandi/screens/kisan/add_new_crop_screen.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';
import 'package:poket_mandi/screens/kisan/services_screen.dart';
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
  // simple in-memory cache to reduce repeated DB reads during a session
  static List<Map<String, dynamic>>? _cropsCache;
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
      // return cached data if available
      if (_cropsCache != null) {
        setState(() {
          crops = List<Map<String, dynamic>>.from(_cropsCache!);
          isLoading = false;
        });
        return;
      }

      // limit query to the latest 100 entries to avoid fetching the entire dataset
      final ref = FirebaseDatabase.instance
          .ref('allcrops')
          .orderByKey()
          .limitToLast(100);
      final snapshot = await ref.once();

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
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LandingScreen()),
          (route) => false,
        );
      }
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
                          MaterialPageRoute(
                            builder: (_) => const LandingScreen(),
                          ),
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

    // Handle Services navigation separately
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
      );
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
                _buildNavItem(Icons.miscellaneous_services, "Services", 4),
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
                        IconButton(
                          onPressed: isGuest
                              ? _showGuestRestrictionDialog
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const UserNotificationsListScreen(),
                                    ),
                                  );
                                },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
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

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Available Crops",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
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
                      icon: const Icon(
                        Icons.add,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: const Text(
                        "Add Crop",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF104f22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ],
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
                            style: TextStyle(fontSize: 16, color: Colors.grey),
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
                            return _buildCropCard(context, crops[index], index);
                          },
                        ),
                ),
                const SizedBox(height: 15),

                /// Removed "Crop not listed?" button from here since it's now in bottom nav
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
    return const KisanHistoryWidget();
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
                            Icon(
                              Icons.visibility,
                              color: Colors.orange,
                              size: 16,
                            ),
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
                  onTap: isGuest
                      ? _showGuestRestrictionDialog
                      : () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );
                          if (result == true) {
                            // Refresh profile data
                            await _loadFarmerData();
                          }
                        },
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.notifications_outlined,
                  title: "Notifications",
                  subtitle: "Manage notification preferences",
                  onTap: isGuest
                      ? _showGuestRestrictionDialog
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.policy_outlined,
                  title: "Policies & Guidelines",
                  subtitle:
                      "Privacy policy, community guidelines & data policy",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildProfileOption(
                  icon: Icons.info_outline,
                  title: "About",
                  subtitle: "App version and information",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
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
              child: Icon(icon, color: const Color(0xFF104f22), size: 24),
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
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class KisanHistoryWidget extends StatefulWidget {
  const KisanHistoryWidget({super.key});

  @override
  State<KisanHistoryWidget> createState() => _KisanHistoryWidgetState();
}

class _KisanHistoryWidgetState extends State<KisanHistoryWidget> {
  List<Map<String, dynamic>> requestedCrops = [];
  bool isLoading = true;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _loadRequestedCrops();
  }

  Future<void> _loadRequestedCrops() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref("requestednewcrop/$userId")
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          temp.add(request);
        });

        temp.sort(
          (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
        );

        setState(() {
          requestedCrops = temp;
          isLoading = false;
        });
      } else {
        setState(() {
          requestedCrops = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        requestedCrops = [];
        isLoading = false;
      });
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  List<Map<String, dynamic>> get filteredRequests {
    if (selectedFilter == "All") {
      return requestedCrops;
    }
    return requestedCrops
        .where((req) => req['status'] == selectedFilter.toLowerCase())
        .toList();
  }

  Color _statusColor(String? status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case "pending":
        return Icons.schedule;
      case "confirmed":
        return Icons.check_circle_outline;
      case "delivered":
        return Icons.done_all;
      case "rejected":
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F5F5),
      child: Column(
        children: [
          _buildCustomAppBar(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF104f22)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadRequestedCrops,
                    color: const Color(0xFF104f22),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [_buildFilterChips(), _buildRequestsList()],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.history, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Request History",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Your crop requests",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
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

  Widget _buildFilterChips() {
    final filters = ["All", "Pending", "Confirmed", "Delivered", "Rejected"];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) => _applyFilter(filter),
                selectedColor: const Color(0xFF104f22),
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                elevation: isSelected ? 4 : 1,
                shadowColor: const Color(0xFF104f22).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF104f22)
                        : Colors.grey.shade300,
                    width: isSelected ? 0 : 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRequestsList() {
    final filtered = filteredRequests;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No requests found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your crop requests will appear here",
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(filtered[index]);
      },
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final cropName = request['cropName'] ?? "Unknown";
    final quantity = request['quantity']?.toString() ?? "0";
    final unit = request['unit'] ?? "Kg";
    final expectedPrice = (request['expectedPrice'] ?? 0).toDouble();
    final qty = (request['quantity'] ?? 0).toDouble();
    final amount = expectedPrice * qty;
    final status = request['status'] ?? "pending";
    final imageUrl = request['imageUrl'];
    final videoUrl = request['videoUrl'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _statusColor(status).withOpacity(0.15),
                  _statusColor(status).withOpacity(0.05),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _statusIcon(status),
                    color: _statusColor(status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Request #${request['id']?.toString().substring(0, 8) ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(status),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    "₹${amount.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF104f22)),
                  ),
                ),
                errorWidget: (context, url, error) {
                  return Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported, size: 50),
                  );
                },
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(Icons.agriculture, "Crop", cropName),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.scale,
                        "Quantity",
                        "$quantity $unit",
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoRow(
                        Icons.currency_rupee,
                        "Expected Price",
                        "₹$expectedPrice/$unit",
                      ),
                    ),
                    Expanded(
                      child: _buildInfoRow(
                        Icons.calendar_today,
                        "Requested On",
                        _formatDate(request['createdAt'] ?? 0),
                      ),
                    ),
                  ],
                ),
                if (videoUrl != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.videocam,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Video attached",
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: Colors.grey[700]),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E2E2E),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    if (timestamp == 0) return 'N/A';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}";
  }
}

class KisanDashboardScreenWithTab extends StatefulWidget {
  final int initialTab;

  const KisanDashboardScreenWithTab({super.key, required this.initialTab});

  @override
  State<KisanDashboardScreenWithTab> createState() =>
      _KisanDashboardScreenWithTabState();
}

class _KisanDashboardScreenWithTabState
    extends State<KisanDashboardScreenWithTab> {
  String farmerName = "Kisan";
  String farmerPhone = "";
  String farmerImage = "https://i.pravatar.cc/300";
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;
  bool isGuest = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
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

  void _onBottomNavTap(int index) {
    if (isGuest && index != 0) {
      return;
    }

    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const KisanDashboardScreen()),
      );
      return;
    }

    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServicesScreen()),
      );
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
          ? Container() // Home screen placeholder
          : _selectedIndex == 1
          ? const MyOrdersScreen()
          : _selectedIndex == 2
          ? const KisanHistoryWidget()
          : Container(), // Profile screen placeholder
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
                _buildNavItem(Icons.miscellaneous_services, "Services", 4),
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
}
