import 'package:flutter/material.dart';
import 'package:poket_mandi/screens/kisan/add_new_crop_screen.dart';
import 'package:poket_mandi/screens/kisan/selected_crop_screen.dart';

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          /// ================= TOP HEADER =================
          Stack(
            children: [
              /// Background Image
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

              /// Dark Overlay
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
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
                        ],
                      ),

                      const SizedBox(height: 15),

                      /// Farmer + Text
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset("assets/images/farmer2.png", height: 120),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              const SizedBox(height: 8),
                              Text(
                                "Kisan Dashboard",
                                style: TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                "Welcome back, Kisan Ji",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
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

          /// ================= CROPS SECTION =================
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
                    "Crops",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  /// Grid
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
                          context,
                          crops[index]["name"]!,
                          crops[index]["image"]!,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  /// Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddNewCropScreen(),
                          ),
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
                        "Crop not listed?",
                        style: TextStyle(color: Colors.white),
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

  Widget _buildCropCard(BuildContext context, String name, String imagePath) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                SelectedCropScreen(cropName: name, imagePath: imagePath),
          ),
        );
      },
      child: Ink(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
        child: Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(imagePath, fit: BoxFit.cover),
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
}
