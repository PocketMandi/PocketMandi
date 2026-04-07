import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poket_mandi/screens/kisan/kisan_dashboard_screen.dart';
import 'package:poket_mandi/screens/vyapari/vyapari_dashboard_screen.dart';
import 'package:poket_mandi/screens/admin/admin_dashboard_screen.dart';
import 'package:poket_mandi/services/notification_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? verificationId;
  final Map<String, String>? userData;
  final bool isTrader;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.verificationId,
    this.userData,
    this.isTrader = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
  bool isLoading = false;
  bool isResending = false;
  String? _currentVerificationId;
  int _resendToken = 0;
  int resendCountdown = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _currentVerificationId = widget.verificationId;
    _startResendCountdown();
  }

  void _startResendCountdown() {
    setState(() => resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (resendCountdown > 0) {
          setState(() => resendCountdown--);
        } else {
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }
    for (var focusNode in focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> resendOtp() async {
    if (resendCountdown > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait $resendCountdown seconds before resending OTP'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() => isResending = true);

    try {
      for (var controller in controllers) {
        controller.clear();
      }
      
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${widget.phoneNumber}',
        verificationCompleted: (PhoneAuthCredential credential) async {
          print('Auto verification completed on resend');
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => isResending = false);
          
          String errorMessage = 'Failed to resend OTP';
          if (e.code == 'too-many-requests') {
            errorMessage = 'Too many requests. Please wait 1-2 hours and try again.\n\nIf urgent, contact support.';
          } else if (e.code == 'invalid-phone-number') {
            errorMessage = 'Invalid phone number format.';
          } else if (e.code == 'quota-exceeded') {
            errorMessage = 'SMS quota exceeded. Please try again later.';
          } else {
            errorMessage = 'Failed to resend OTP: ${e.message}';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            isResending = false;
            _currentVerificationId = verificationId;
            if (resendToken != null) {
              _resendToken = resendToken;
            }
          });
          
          _startResendCountdown();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP resent successfully! It may take up to 2 minutes to arrive.'),
              backgroundColor: Color(0xFF104f22),
              duration: Duration(seconds: 3),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _currentVerificationId = verificationId;
        },
        forceResendingToken: _resendToken > 0 ? _resendToken : null,
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      setState(() => isResending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resending OTP: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Future<void> verifyOtpAndRegister() async {
    String enteredOtp = controllers.map((c) => c.text).join();

    if (enteredOtp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter complete 6-digit OTP"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      if (_currentVerificationId == null) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification ID not found. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _currentVerificationId!,
        smsCode: enteredOtp,
      );

      // Verify OTP
      try {
        await FirebaseAuth.instance.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        setState(() => isLoading = false);
        String errorMessage = "OTP verification failed";
        
        if (e.code == 'invalid-verification-code') {
          errorMessage = "Invalid OTP. Please check and try again.";
        } else if (e.code == 'session-expired') {
          errorMessage = "OTP expired. Please request a new one.";
        } else if (e.code == 'too-many-requests') {
          errorMessage = "Too many attempts. Please try again later.";
        } else {
          errorMessage = "OTP verification failed: ${e.message}";
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Registration flow
      if (widget.userData != null) {
        try {
          final snapshot = await FirebaseDatabase.instance
              .ref("users/$uid")
              .get();

          if (snapshot.exists) {
            await FirebaseAuth.instance.signOut();
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("This phone number is already registered. Please login instead."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          await FirebaseDatabase.instance.ref("users/$uid").set({
            ...widget.userData!,
            "id": uid,
            "role": widget.isTrader ? "trader" : "farmer",
            "isBlocked": false,
            "kycStatus": "pending",
            "createdAt": DateTime.now().toIso8601String(),
          });

          await NotificationService.sendNotificationToAdmins(
            title: 'New User Registered',
            body: '${widget.userData!["name"]} registered as ${widget.isTrader ? "Trader" : "Farmer"}',
            type: 'new_user',
            data: {'userId': uid, 'userRole': widget.isTrader ? 'trader' : 'farmer'},
          );

          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('is_guest');
          await prefs.remove('guest_role');
          await prefs.setString('user_id', uid);
          await prefs.setString('user_role', widget.isTrader ? 'trader' : 'farmer');
          await prefs.setString('name', widget.userData!['name'] ?? '');
          await prefs.setString('phone', widget.userData!['phone'] ?? '');
          await prefs.setString('state', widget.userData!['state'] ?? '');
          await prefs.setString('district', widget.userData!['district'] ?? '');
          await prefs.setString('address', widget.userData!['address'] ?? '');
          await prefs.setString('profileImageUrl', widget.userData!['profileImageUrl'] ?? '');

          final fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null) {
            await FirebaseDatabase.instance.ref('users/$uid/fcmToken').set(fcmToken);
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => widget.isTrader ? VyapariDashboardScreen() : KisanDashboardScreen(),
            ),
            (route) => false,
          );
        } on FirebaseException catch (e) {
          await FirebaseAuth.instance.signOut();
          setState(() => isLoading = false);
          
          String errorMessage = "Registration failed";
          if (e.code == 'permission-denied') {
            errorMessage = "Database permission denied. Please contact support.";
          } else if (e.code == 'network-request-failed') {
            errorMessage = "Network error. Please check your internet connection.";
          } else {
            errorMessage = "Registration failed: ${e.message}";
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          await FirebaseAuth.instance.signOut();
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Unexpected error during registration: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      // Login flow - Check if user exists by phone number
      else {
        try {
          final phoneSnapshot = await FirebaseDatabase.instance
              .ref("users")
              .orderByChild("phone")
              .equalTo(widget.phoneNumber)
              .once();

          if (phoneSnapshot.snapshot.value == null) {
            await FirebaseAuth.instance.signOut();
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Phone number not registered. Please register as Kisan or Vyapari first."),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }

          final data = phoneSnapshot.snapshot.value as Map;
          final oldUserId = data.keys.first;
          final userData = Map<String, dynamic>.from(data.values.first as Map);

          if (userData['isBlocked'] == true) {
            await FirebaseAuth.instance.signOut();
            setState(() => isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("You are blocked by Super Admin. You cannot login."),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }

          final role = userData['role'] as String;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('is_guest');
          await prefs.remove('guest_role');
          await prefs.setString('user_id', oldUserId);
          await prefs.setString('user_role', role);
          await prefs.setString('name', userData['name']?.toString() ?? '');
          await prefs.setString('phone', userData['phone']?.toString() ?? '');
          await prefs.setString('state', userData['state']?.toString() ?? '');
          await prefs.setString('village', userData['village']?.toString() ?? '');
          await prefs.setString('profileImage', userData['profileImage']?.toString() ?? '');

          final fcmToken = await NotificationService.getFCMToken();
          if (fcmToken != null) {
            await FirebaseDatabase.instance.ref('users/$oldUserId/fcmToken').set(fcmToken);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Welcome back, ${userData['name']}!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) {
                if (role == "farmer") return KisanDashboardScreen();
                if (role == "trader") return VyapariDashboardScreen();
                if (role == "admin" || role == "superadmin") return const AdminDashboardScreen();
                return KisanDashboardScreen();
              },
            ),
            (route) => false,
          );
        } on FirebaseException catch (e) {
          await FirebaseAuth.instance.signOut();
          setState(() => isLoading = false);
          
          String errorMessage = "Login failed";
          if (e.code == 'permission-denied') {
            errorMessage = "Database permission denied. Please update Firebase rules or contact support.";
          } else if (e.code == 'network-request-failed') {
            errorMessage = "Network error. Please check your internet connection.";
          } else if (e.code == 'unavailable') {
            errorMessage = "Database unavailable. Please try again later.";
          } else {
            errorMessage = "Login failed: ${e.message}";
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          await FirebaseAuth.instance.signOut();
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Unexpected error during login: $e"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An unexpected error occurred: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
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
            child: Column(
              children: [
                /// 🔙 Back Button
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
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
                                const Text(
                                  "PoketMandi",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          /// Title Section
                          Column(
                            children: [
                              const Text(
                                "Verify OTP",
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
                              Text(
                                "Enter the 6-digit OTP sent to\n+91 ${widget.phoneNumber}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// OTP Verification Card
                          Container(
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
                            child: Container(
                              padding: const EdgeInsets.all(28),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// Header
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF104f22),
                                              Color(0xFF0d3f1c),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.sms_outlined,
                                          size: 24,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "OTP Verification",
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF2E2E2E),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Code sent to +91 ${widget.phoneNumber}",
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 28),

                                  /// OTP Input Label
                                  const Text(
                                    "Enter 6-Digit OTP",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2E2E2E),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  /// OTP Input Boxes
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(6, (index) {
                                      return Flexible(
                                        child: Container(
                                          width: 45,
                                          height: 55,
                                          margin: const EdgeInsets.symmetric(
                                            horizontal: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.05,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: TextField(
                                            controller: controllers[index],
                                            focusNode: focusNodes[index],
                                            keyboardType: TextInputType.number,
                                            textAlign: TextAlign.center,
                                            maxLength: 1,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF104f22),
                                            ),
                                            onChanged: (value) {
                                              if (value.isNotEmpty &&
                                                  index < 5) {
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(
                                                  focusNodes[index + 1],
                                                );
                                              } else if (value.isEmpty &&
                                                  index > 0) {
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(
                                                  focusNodes[index - 1],
                                                );
                                              }
                                            },
                                            decoration: InputDecoration(
                                              counterText: "",
                                              filled: true,
                                              fillColor: Colors.grey[50],
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFF104f22),
                                                  width: 2,
                                                ),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),

                                  const SizedBox(height: 24),

                                  /// Verify Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: isLoading
                                          ? null
                                          : verifyOtpAndRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF104f22,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: 3,
                                        shadowColor: Colors.black.withOpacity(
                                          0.2,
                                        ),
                                      ),
                                      child: isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.verified_user,
                                                  size: 20,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Verify & Continue",
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  /// Resend OTP Section
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF104f22,
                                      ).withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.refresh,
                                          size: 16,
                                          color: Color(0xFF104f22),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Didn't receive OTP? ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: (isResending || resendCountdown > 0) ? null : resendOtp,
                                          child: Text(
                                            isResending 
                                              ? "Sending..." 
                                              : resendCountdown > 0
                                                ? "Resend (${resendCountdown}s)"
                                                : "Resend",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: (isResending || resendCountdown > 0) 
                                                ? Colors.grey 
                                                : const Color(0xFF104f22),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
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
}
