import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import 'package:zrai_mart/saller%20center/storeView/StooreSettingcreen.dart';
import 'dart:async';

import '../../app_colors.dart';
import '../../saller center/bottomTabs/sallerbottomTabs.dart';
import '../bottomTabs/bottomTabs.dart';
// import 'package:zrai_mart/utils/app_colors.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  // --- BACKEND LOGIC PRESERVED ---
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _canResendEmail = true;
  Timer? _resendTimer;
  Timer? _verificationTimer;
  int _countdown = 0;

  @override
  void initState() {
    super.initState();
    _startPeriodicEmailVerificationCheck();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _verificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
      setState(() {
        _canResendEmail = false;
        _countdown = 10;
      });
      _showFloatingSnackBar('Verification email sent!', AppColors.successGreen);
      _startResendCooldown();
    }
  }

  void _startResendCooldown() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
        setState(() => _canResendEmail = true);
      }
    });
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      _showFloatingSnackBar('Signed out successfully', AppColors.primaryGreen);
    } catch (e) {
      _showFloatingSnackBar('Error signing out: $e', AppColors.errorRed);
    }
  }

  void handleLogoutTap() {
    _signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Signinscreen()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser;

      if (user!.emailVerified) {
        // Cancel the timer so it doesn't try to navigate multiple times
        _verificationTimer?.cancel();

        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot sallerDoc = await _firestore.collection('saller').doc(user.uid).get();

        if (userDoc.exists) {
          // Regular Customer -> Home
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BottomTabs()),
                  (route) => false
          );
        } else if (sallerDoc.exists) {
          // Seller detected -> Check for store setup
          var sellerData = sallerDoc.data() as Map<String, dynamic>? ?? {};
          bool hasSetupStore = sellerData['hasSetupStore'] ?? false;

          if (!hasSetupStore) {
            // New Seller: Force store setup
            _showFloatingSnackBar('Email verified! Now, let\'s set up your store.', AppColors.successGreen);
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
                    (route) => false
            );
          } else {
            // Existing Seller: Go to dashboard
            _showFloatingSnackBar('Email verified! Welcome back.', AppColors.successGreen);
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const sallerBottomTabs()),
                    (route) => false
            );
          }
        }
      }
    }
  }

  void _startPeriodicEmailVerificationCheck() {
    _verificationTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _checkEmailVerification();
    });
  }

  void _showFloatingSnackBar(String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verify Email', style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated-style Icon
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_unread_rounded,
                size: 80,
                color: AppColors.primaryGreen,
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              'Check your Inbox!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 15),
            const Text(
              'We have sent a verification link to your email. Please click the link to activate your account.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textGrey, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),

            // Resend Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _canResendEmail ? _sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(
                  _canResendEmail ? 'Resend Email' : 'Resend in $_countdown s',
                  style: TextStyle(
                    color: _canResendEmail ? Colors.white : AppColors.textGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Logout/Cancel Button
            TextButton.icon(
              onPressed: handleLogoutTap,
              icon: const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 20),
              label: const Text(
                "Cancel & Logout",
                style: TextStyle(color: AppColors.errorRed, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 60),
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen),
            ),
            const SizedBox(height: 10),
            const Text(
              "Waiting for verification...",
              style: TextStyle(color: AppColors.textGrey, fontStyle: FontStyle.italic, fontSize: 13),
            )
          ],
        ),
      ),
    );
  }
}