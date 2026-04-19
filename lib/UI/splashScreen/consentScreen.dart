import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import '../../app_colors.dart';
import '../../saller center/bottomTabs/sallerbottomTabs.dart';
import '../auth/EmailVerificationScreen.dart';
import '../bottomTabs/bottomTabs.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class Consentscreen extends StatefulWidget {
  const Consentscreen({super.key});

  @override
  State<Consentscreen> createState() => _ConsentscreenState();
}

class _ConsentscreenState extends State<Consentscreen> {
  // --- BACKEND LOGIC PRESERVED ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // LOGIC: Check if user is logged in, verified, and their role (Seller/Buyer)
  Future<void> _checkLoginStatus() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot sallerDoc = await _firestore.collection('saller').doc(user.uid).get();

        if (user.emailVerified) {
          if (userDoc.exists) {
            Fluttertoast.showToast(msg: "Sign-in successful!");
            Timer(const Duration(seconds: 2), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const BottomTabs())));
          } else if (sallerDoc.exists) {
            Fluttertoast.showToast(msg: "Sign-in successful!");
            Timer(const Duration(seconds: 2), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const sallerBottomTabs())));
          } else {
            Fluttertoast.showToast(msg: "User record not found!");
            Timer(const Duration(seconds: 2), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Signinscreen())));
          }
        } else {
          Fluttertoast.showToast(msg: "Please verify your email!");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmailVerificationScreen()));
        }
      } else {
        Timer(const Duration(seconds: 3), () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const Signinscreen())));
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "Connection error. Retrying...");
      _delayedCheckLoginStatus();
    }
  }

  void _delayedCheckLoginStatus() {
    Timer(const Duration(seconds: 10), () => _checkLoginStatus());
  }

  @override
  Widget build(BuildContext context) {
    const text1 = "The best crops e-commerce & online Store";
    const text2 = "Everything you need for your farm";

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/img.jpg",
              fit: BoxFit.cover,
            ),
          ),

          // 2. Dark Gradient Overlay (Makes text pop)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  const Text(
                    "Welcome to",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Text(
                    "Digital\nGalla Mandi",
                    style: TextStyle(
                      color: AppColors.primaryGreen,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    text2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    text1,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 50),

                  // Loading Indicator at the bottom
                  const Center(
                    child: CupertinoActivityIndicator(
                      color: Colors.white,
                      radius: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}