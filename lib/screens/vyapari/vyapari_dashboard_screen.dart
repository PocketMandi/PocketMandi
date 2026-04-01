import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/auth/landing_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_detail_screen.dart';
import 'package:poket_mandi/screens/vyapari/crop_not_listed_screen.dart';
import 'package:poket_mandi/screens/kisan/edit_profile_screen.dart';
import 'package:poket_mandi/screens/common/about_screen.dart';
import 'package:poket_mandi/screens/common/policies_screen.dart';
import 'package:poket_mandi/screens/common/notifications_screen.dart';
import 'package:poket_mandi/screens/common/user_notifications_list_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VyapariDashboardScreen extends StatefulWidget {
  final int? initialTab;

  const VyapariDashboardScreen({super.key, this.initialTab});

  @override
  State<VyapariDashboardScreen> createState() => _VyapariDashboardScreenState();
}

class _VyapariDashboardScreenState extends State<VyapariDashboardScreen> {
  String traderName = "Vyapari";
  String traderPhone = "";
  String traderImage = "https://i.pravatar.cc/300";
  // Enhanced caching with timestamp for better performance
  static List<Map<String, dynamic>>? _cropsCache;
  static DateTime? _cropsCacheTime;
  List<Map<String, dynamic>> crops = [];
  bool isLoading = true;
  bool isGuest = false;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab ?? 0;
    _initializeUserData();
    _loadCrops();
  }

  Future<void> _initializeUserData() async {
    await _checkGuestMode();
    await _loadTraderData();
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

  Future<void> _loadCrops() async {
    try {
      // return cached data if available and not expired (5 minutes)
      if (_cropsCache != null &&
          _cropsCacheTime != null &&
          DateTime.now().difference(_cropsCacheTime!).inMinutes < 5) {
        setState(() {
          crops = List<Map<String, dynamic>>.from(_cropsCache!);
          isLoading = false;
        });
        return;
      }

      // Optimized query with indexed ordering and increased limit for better UX
      final ref = FirebaseDatabase.instance
          .ref('allcrops')
          .orderByChild('createdAt')
          .limitToLast(200);
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

          // Cache the results with timestamp
          _cropsCache = List<Map<String, dynamic>>.from(crops);
          _cropsCacheTime = DateTime.now();
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
                          MaterialPageRoute(
                            builder: (_) => const LandingScreen(),
                          ),
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

  void _onBottomNavTap(int index) {
    if (isGuest && index != 0) {
      _showGuestRestrictionDialog();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  List<Map<String, String>> get cropNames => crops
      .map(
        (crop) => {
          "name": crop["name"]?.toString() ?? "Unknown",
          "image": crop["image"]?.toString() ?? "assets/images/login_bg.jpg",
        },
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
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
                _buildCropNotListedNavItem(),
                _buildNavItem(Icons.history, "History", 2),
                _buildNavItem(Icons.person, "Profile", 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropNotListedNavItem() {
    return Expanded(
      child: InkWell(
        onTap: isGuest
            ? _showGuestRestrictionDialog
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CropNotListedScreen()),
                );
              },
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF669123), Color(0xFF104f22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF669123).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: Colors.white, size: 24),
              SizedBox(height: 2),
              Text(
                "Request",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
        /// Header Section
        Container(
          height: 200,
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
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    /// Top Row with Logo and Profile
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Logo Section
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.asset(
                                  "assets/images/logof.png",
                                  width: 28,
                                  height: 28,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "PoketMandi",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  "Trader Dashboard",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        /// Profile Section
                        Row(
                          children: [
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.white,
                                backgroundImage: traderImage.startsWith('http')
                                    ? CachedNetworkImageProvider(traderImage)
                                    : null,
                                child: !traderImage.startsWith('http')
                                    ? const Icon(
                                        Icons.person,
                                        size: 22,
                                        color: Color(0xFF104f22),
                                      )
                                    : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    /// Welcome Section
                    Column(
                      children: [
                        Text(
                          "Welcome back,",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "$traderName Ji",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),

                        /// Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isGuest
                                ? Colors.orange.withOpacity(0.9)
                                : Colors.green.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isGuest
                                    ? Icons.visibility
                                    : Icons.verified_user,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isGuest ? "Guest Mode" : "Verified Trader",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Content Section
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                /// Available Crops Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader("Available Crops", Icons.inventory),
                      const SizedBox(height: 15),
                      isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: CircularProgressIndicator(
                                  color: Color(0xFF104f22),
                                ),
                              ),
                            )
                          : crops.isEmpty
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  "No crops available.\nPlease check back later!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: crops.length,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1.1,
                                  ),
                              itemBuilder: (context, index) {
                                return _buildCropCard(crops[index], index);
                              },
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF104f22), size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF104f22),
          ),
        ),
      ],
    );
  }

  Widget _buildCropCard(Map<String, dynamic> cropData, int index) {
    final name = cropData["name"]?.toString() ?? "Unknown";
    final imagePath =
        cropData["image"]?.toString() ?? "assets/images/login_bg.jpg";

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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              /// Image
              Expanded(
                flex: 3,
                child: imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
                                  'Image unavailable',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Image.asset(
                        imagePath,
                        width: double.infinity,
                        fit: BoxFit.cover,
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

              /// Name
              Expanded(
                flex: 1,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  child: Center(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildOrdersScreen() {
    return MyOrdersVyapariWidget(
      onBackPressed: () {
        setState(() {
          _selectedIndex = 0; // Go back to home tab
        });
      },
    );
  }

  Widget _buildHistoryScreen() {
    return MyOrdersVyapariHistoryWidget(
      onBackPressed: () {
        setState(() {
          _selectedIndex = 0; // Go back to home tab
        });
      },
    );
  }

  Widget _buildProfileScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          /// Profile Header
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
                        backgroundImage: traderImage.startsWith('http')
                            ? CachedNetworkImageProvider(traderImage)
                            : null,
                        child: !traderImage.startsWith('http')
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: Color(0xFF104f22),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      traderName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      traderPhone,
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

          /// Profile Options
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
                            await _loadTraderData();
                            setState(() {});
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

class MyOrdersVyapariWidget extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const MyOrdersVyapariWidget({super.key, this.onBackPressed});

  @override
  State<MyOrdersVyapariWidget> createState() => _MyOrdersVyapariWidgetState();
}

class _MyOrdersVyapariWidgetState extends State<MyOrdersVyapariWidget> {
  List<Map<String, dynamic>> myOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;
  String selectedFilter = "All";

  int totalOrders = 0;
  int pendingOrders = 0;
  int confirmedOrders = 0;
  int deliveredOrders = 0;
  double totalSpent = 0.0;

  @override
  void initState() {
    super.initState();
    _loadMyOrders();
  }

  Future<void> _loadMyOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        setState(() => isLoading = false);
        return;
      }

      // Load from requestednewcropbyvyapari
      final requestedSnapshot = await FirebaseDatabase.instance
          .ref("requestednewcropbyvyapari/$userId")
          .get();

      // Load from addedcropsbyvyapari
      final addedSnapshot = await FirebaseDatabase.instance
          .ref("addedcropsbyvyapari/$userId")
          .get();

      List<Map<String, dynamic>> tempOrders = [];

      // Add requested crops
      if (requestedSnapshot.value != null) {
        final data = requestedSnapshot.value as Map;
        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          order['source'] = 'requested';
          tempOrders.add(order);
        });
      }

      // Add added crops
      if (addedSnapshot.value != null) {
        final data = addedSnapshot.value as Map;
        data.forEach((key, value) {
          final order = Map<String, dynamic>.from(value);
          order['id'] = key;
          order['source'] = 'added';
          tempOrders.add(order);
        });
      }

      tempOrders.sort(
        (a, b) => (b['createdAt'] ?? 0).compareTo(a['createdAt'] ?? 0),
      );

      _calculateStatistics(tempOrders);

      setState(() {
        myOrders = tempOrders;
        filteredOrders = tempOrders;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        myOrders = [];
        filteredOrders = [];
        isLoading = false;
      });
    }
  }

  void _calculateStatistics(List<Map<String, dynamic>> orders) {
    totalOrders = orders.length;
    pendingOrders = orders.where((o) => o['status'] == 'pending').length;
    confirmedOrders = orders.where((o) => o['status'] == 'confirmed').length;
    deliveredOrders = orders.where((o) => o['status'] == 'delivered').length;

    totalSpent = 0.0;
    for (var order in orders) {
      final price = (order['pricePerUnit'] ?? 0).toDouble();
      final qty = (order['quantity'] ?? 0).toDouble();
      totalSpent += price * qty;
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "All") {
        filteredOrders = myOrders;
      } else {
        filteredOrders = myOrders
            .where((order) => order['status'] == filter.toLowerCase())
            .toList();
      }
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "confirmed":
        return Colors.blue;
      case "delivered":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case "pending":
        return Icons.schedule;
      case "confirmed":
        return Icons.check_circle_outline;
      case "delivered":
        return Icons.done_all;
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
                    onRefresh: _loadMyOrders,
                    color: const Color(0xFF104f22),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          _buildStatisticsCards(),
                          _buildFilterChips(),
                          _buildOrdersList(),
                        ],
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "My Orders",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Track your crop requests",
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

  Widget _buildStatisticsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Total Orders",
                  totalOrders.toString(),
                  Icons.inventory_2,
                  const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Pending",
                  pendingOrders.toString(),
                  Icons.schedule,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  "Confirmed",
                  confirmedOrders.toString(),
                  Icons.check_circle_outline,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  "Delivered",
                  deliveredOrders.toString(),
                  Icons.done_all,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTotalSpentCard(),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpentCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF104f22), Color(0xFF0d3f1c)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF104f22).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.currency_rupee,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${totalSpent.toStringAsFixed(2)}",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["All", "Pending", "Confirmed", "Delivered"];
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

  Widget _buildOrdersList() {
    if (filteredOrders.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No orders found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Your orders will appear here",
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
      itemCount: filteredOrders.length,
      itemBuilder: (context, index) {
        return _buildOrderCard(filteredOrders[index]);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final source = order['source'] ?? 'added';
    final cropType = order['cropType'] ?? order['cropName'] ?? "Unknown";
    final quantity = order['quantity']?.toString() ?? "0";
    final unit = order['unit'] ?? "Kg";
    final status = order['status'] ?? "unknown";

    // Handle different data structures
    final price = source == 'requested'
        ? (order['expectedPrice'] ?? 0).toDouble()
        : (order['pricePerUnit'] ?? 0).toDouble();
    final qty = (order['quantity'] ?? 0).toDouble();
    final amount = (price * qty);

    final grades = source == 'added'
        ? ((order['qualityGrades'] as List?)?.join(", ") ?? "N/A")
        : "N/A";
    final location = order['location'] != null
        ? order['location']['deliveryAddress'] ?? "N/A"
        : "N/A";
    final deliveryDate = order['requiredDeliveryDate'];
    final mandiName = order['location'] != null
        ? order['location']['mandiName'] ?? "N/A"
        : "N/A";
    final imageUrl = order['imageUrl'];
    final videoUrl = order['videoUrl'];

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
                        "${source == 'requested' ? 'Request' : 'Order'} #${order['id']?.toString().substring(0, 8) ?? 'N/A'}",
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
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
                      child: _buildInfoRow(Icons.agriculture, "Crop", cropType),
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
                        source == 'requested'
                            ? 'Expected Price'
                            : 'Price per kg',
                        "₹${price.toStringAsFixed(2)}/$unit",
                      ),
                    ),
                    if (source == 'added' && grades != 'N/A')
                      Expanded(
                        child: _buildInfoRow(Icons.grade, "Grade", grades),
                      ),
                  ],
                ),
                if (source == 'added') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (mandiName != 'N/A')
                        Expanded(
                          child: _buildInfoRow(Icons.store, "Mandi", mandiName),
                        ),
                      if (deliveryDate != null)
                        Expanded(
                          child: _buildInfoRow(
                            Icons.calendar_today,
                            "Delivery Date",
                            _formatDate(deliveryDate),
                          ),
                        ),
                    ],
                  ),
                  if (order['specialInstructions'] != null &&
                      order['specialInstructions'].toString().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      Icons.note,
                      "Special Instructions",
                      order['specialInstructions'].toString(),
                    ),
                  ],
                ],
                if (source == 'requested' && videoUrl != null) ...[
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
                maxLines: label == "Special Instructions" ? 2 : 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return "${date.day}/${date.month}/${date.year}";
  }
}

class MyOrdersVyapariHistoryWidget extends StatefulWidget {
  final VoidCallback? onBackPressed;

  const MyOrdersVyapariHistoryWidget({super.key, this.onBackPressed});

  @override
  State<MyOrdersVyapariHistoryWidget> createState() =>
      _MyOrdersVyapariHistoryWidgetState();
}

class _MyOrdersVyapariHistoryWidgetState
    extends State<MyOrdersVyapariHistoryWidget> {
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

      // Load all requested crops for this user
      final snapshot = await FirebaseDatabase.instance
          .ref("requestednewcropbyvyapari/$userId")
          .get();

      if (snapshot.value != null) {
        final data = snapshot.value as Map;
        List<Map<String, dynamic>> temp = [];

        data.forEach((key, value) {
          final request = Map<String, dynamic>.from(value);
          request['id'] = key;
          temp.add(request);
        });

        // Sort by createdAt in descending order (newest first)
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
      print('Error loading requested crops: $e'); // Debug print
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
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    if (widget.onBackPressed != null) {
                      widget.onBackPressed!();
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                  ),
                ),
              ),
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
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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

class VyapariDashboardScreenWithTab extends StatefulWidget {
  final int initialTab;

  const VyapariDashboardScreenWithTab({super.key, required this.initialTab});

  @override
  State<VyapariDashboardScreenWithTab> createState() =>
      _VyapariDashboardScreenWithTabState();
}

class _VyapariDashboardScreenWithTabState
    extends State<VyapariDashboardScreenWithTab> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      body: _selectedIndex == 2
          ? const MyOrdersVyapariHistoryWidget()
          : _selectedIndex == 1
          ? const MyOrdersVyapariWidget()
          : Container(),
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
                _buildCropNotListedNavItem(),
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
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
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

  Widget _buildCropNotListedNavItem() {
    return Expanded(
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(25),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF669123), Color(0xFF104f22)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF669123).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle, color: Colors.white, size: 24),
              SizedBox(height: 2),
              Text(
                "Request",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
