import 'package:flutter/material.dart';
import 'package:poket_mandi/screens/admin/admin_dashboard_screen.dart';
import 'package:poket_mandi/screens/admin/debug_data_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/auth/landing_screen.dart';
import 'package:poket_mandi/screens/kisan/kisan_dashboard_screen.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:poket_mandi/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Firebase Messaging background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoketMandi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      navigatorKey: _navigatorKey,
      home: const AuthCheck(),
      // home: const AdminDashboardScreen(),
    );
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
    // Set notification context after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navigatorKey.currentContext != null) {
        NotificationService.setContext(_navigatorKey.currentContext!);
      }
    });
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    final userRole = prefs.getString('user_role');

    if (userId != null && userRole != null) {
      // User is logged in, navigate to appropriate dashboard
      Widget dashboard;
      if (userRole == 'farmer') {
        dashboard = KisanDashboardScreen();
      } else if (userRole == 'trader') {
        dashboard = VyapariDashboardScreen();
      } else if (userRole == 'admin' || userRole == 'superadmin') {
        dashboard = const AdminDashboardScreen();
      } else {
        // Default to landing screen if role is unknown
        dashboard = LandingScreen();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
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
