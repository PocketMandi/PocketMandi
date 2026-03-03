import 'package:flutter/material.dart';

class KisanDashboardScreen extends StatelessWidget {
  const KisanDashboardScreen({super.key});

  final List<Map<String, String>> crops = const [
    {"name": "Wheat", "image": "assets/images/login_bg.jpg"},
    {"name": "Rice", "image": "assets/images/rice.jpg"},
    {"name": "Tomato", "image": "assets/images/tomato.jpg"},
    {"name": "Potato", "image": "assets/images/potato.jpg"},
    {"name": "Chilli", "image": "assets/images/chilli.jpg"},
    {"name": "Mustard", "image": "assets/images/mustard.jpg"},
    {"name": "Cotton", "image": "assets/images/cotton.jpg"},
    {"name": "Maize", "image": "assets/images/maize.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // /// 🌾 Background
          // SizedBox.expand(
          //   child: Image.asset("assets/images/login_bg.jpg", fit: BoxFit.cover),
          // ),

          /// 🌫 Overlay
          Container(color: Colors.black.withOpacity(0.35)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset("assets/images/farmer2.png", height: 80),

                      Column(
                        children: [
                          const Text(
                            "Kisan Dashboard",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 5),

                          const Text(
                            "Welcome back, Kisan Ji",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Crops",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// 🌱 Crops Grid
                  Expanded(
                    child: GridView.builder(
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
                          crops[index]["name"]!,
                          crops[index]["image"]!,
                        );
                      },
                    ),
                  ),

                  /// Crop Not Listed Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF2EEDC),
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Crop not listed?",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🌾 Crop Card Widget
  Widget _buildCropCard(String name, String imagePath) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),

          /// Dark overlay
          Container(color: Colors.black.withOpacity(0.3)),

          Positioned(
            bottom: 8,
            left: 8,
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
