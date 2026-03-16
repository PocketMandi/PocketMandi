import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/kisan/kisan_dashboard_screen.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';

class GuestSelectionScreen extends StatelessWidget {
  const GuestSelectionScreen({super.key});

  Future<void> _loginAsGuest(BuildContext context, String role) async {
    final prefs = await SharedPreferences.getInstance();

    // Set guest mode flags
    await prefs.setBool('is_guest', true);
    await prefs.setString('guest_role', role);
    await prefs.setString('name', 'Guest User');
    await prefs.setString('phone', 'Guest Mode');

    // Navigate to appropriate dashboard
    if (role == 'kisan') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const KisanDashboardScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VyapariDashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌾 Background Image
          SizedBox.expand(
            child: Image.asset("assets/images/login_bg.jpg", fit: BoxFit.cover),
          ),

          /// 🌫 Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                  Colors.black.withOpacity(0.8),
                ],
              ),
            ),
          ),

          /// 📱 Content
          SafeArea(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height - 
                      MediaQuery.of(context).padding.top - 
                      MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    /// 🔙 Back Button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// Header Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          /// 🔰 Logo + App Name
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      "assets/images/logof.png",
                                      width: 35,
                                      height: 35,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    const Text(
                                      "Poket",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const Text(
                                      "Mandi",
                                      style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),

                          /// Title Section
                          Column(
                            children: [
                              const Text(
                                "Browse as Guest",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 3,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF104f22),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Choose your role to explore the marketplace",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          /// Selection Cards
                          Column(
                            children: [
                              /// Kisan Guest Card
                              _buildGuestCard(
                                context: context,
                                title: "Browse as Kisan",
                                subtitle: "किसान अतिथि",
                                description: "View available crops & marketplace",
                                imagePath: "assets/images/farmer2.png",
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF104f22),
                                    Color(0xFF0d3f1c),
                                  ],
                                ),
                                onTap: () => _loginAsGuest(context, 'kisan'),
                              ),

                              const SizedBox(height: 20),

                              /// Vyapari Guest Card
                              _buildGuestCard(
                                context: context,
                                title: "Browse as Vyapari",
                                subtitle: "व्यापारी अतिथि",
                                description: "Explore farmer listings & products",
                                imagePath: "assets/images/farmer2.png", // Using farmer2.png as fallback
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2E7D32),
                                    Color(0xFF1B5E20),
                                  ],
                                ),
                                onTap: () => _loginAsGuest(context, 'vyapari'),
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          /// Info Panel
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        "Guest Mode Limitations",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.visibility,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Browse crops and marketplace",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.block,
                                      size: 16,
                                      color: Colors.redAccent,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Cannot add crops or make orders",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.account_circle_outlined,
                                      size: 16,
                                      color: Colors.white70,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Register for full access to all features",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
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

  Widget _buildGuestCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required String imagePath,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.95),
                  Colors.white.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                /// Image Container
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: gradient,
                      ),
                      child: Stack(
                        children: [
                          // Gradient overlay on image
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.black.withOpacity(0.3),
                                  Colors.black.withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                          // Image
                          Image.asset(
                            imagePath,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                /// Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E2E2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF104f22),
                          fontFamily: 'Noto Sans Devanagari',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                /// Arrow Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF104f22).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Color(0xFF104f22),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
