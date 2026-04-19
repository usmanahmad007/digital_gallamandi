import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/splashScreen/consentScreen.dart';
import 'package:zrai_mart/UI/bottomTabs/bottomTabs.dart';
import 'package:zrai_mart/saller%20center/bottomTabs/sallerbottomTabs.dart';
import 'package:zrai_mart/saller%20center/storeView/StooreSettingcreen.dart';
import '../../app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation Logic
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Start checking auth status after a small delay for the animation
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    // Wait for 3 seconds total (splash duration)
    await Future.delayed(const Duration(seconds: 3));

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // 1. No user logged in -> Go to Consent/Login Screen
      _navigateTo(const Consentscreen());
    } else {
      try {
        // 2. Check if user exists in 'users' collection (Customer)
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          _navigateTo(const BottomTabs());
          return;
        }

        // 3. Check if user exists in 'saller' collection (Seller)
        DocumentSnapshot sellerDoc = await FirebaseFirestore.instance.collection('saller').doc(user.uid).get();
        if (sellerDoc.exists) {
          var sellerData = sellerDoc.data() as Map<String, dynamic>? ?? {};
          bool hasSetupStore = sellerData['hasSetupStore'] ?? false;

          if (!hasSetupStore) {
            // Seller exists but hasn't setup store -> Go to Setup
            _navigateTo(const StoreSettingsScreen());
          } else {
            // Seller is verified and setup -> Go to Dashboard
            _navigateTo(const sallerBottomTabs());
          }
        } else {
          // If logged in but no data found (fallback)
          _navigateTo(const Consentscreen());
        }
      } catch (e) {
        // Handle potential errors (like no internet)
        debugPrint("Splash Error: $e");
        _navigateTo(const Consentscreen());
      }
    }
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            bottom: -50,
            left: -50,
            child: CircleAvatar(
              radius: 100,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.05),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset("assets/img_1.png", width: 220, height: 220),
                  const SizedBox(height: 20),
                  Text(
                    "DIGITAL GALLA MANDI",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primaryGreen.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
                ),
                const SizedBox(height: 20),
                Text(
                  "Empowering Farmers Digitally",
                  style: TextStyle(
                    color: AppColors.textGrey.withOpacity(0.6),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
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