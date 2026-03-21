import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/auth/landing_screen.dart';
import 'package:poket_mandi/screens/kisan/kisan_dashboard_screen.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Uncomment below line to add crops to Firebase (run once only)
  // await addAllCropsToFirebase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketMandi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');

    if (userId != null && userRole != null) {
      // User is logged in, navigate to dashboard
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => userRole == 'farmer'
              ? KisanDashboardScreen()
              : VyapariDashboardScreen(),
        ),
      );
    } else {
      // User not logged in, show landing screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
