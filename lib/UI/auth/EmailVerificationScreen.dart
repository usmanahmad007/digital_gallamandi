import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/auth/signInScreen.dart';
import 'dart:async'; // Import Timer

import '../../saller center/bottomTabs/sallerbottomTabs.dart';
import '../bottomTabs/bottomTabs.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  _EmailVerificationScreenState createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _canResendEmail = true; // Track if the email can be resent
  Timer? _resendTimer; // Timer for managing resend cooldown
  Timer? _verificationTimer; // Timer for periodic email verification check
  int _countdown = 0; // Countdown value for displaying remaining time

  @override
  void initState() {
    super.initState();
    _startPeriodicEmailVerificationCheck();
  }

  @override
  void dispose() {
    _resendTimer?.cancel(); // Cancel the resend cooldown timer
    _verificationTimer?.cancel(); // Cancel the periodic verification check timer
    super.dispose();
  }

  Future<void> _sendVerificationEmail() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.sendEmailVerification();
      setState(() {
        _canResendEmail = false; // Disable resend button
        _countdown = 10; // Set countdown to 10 seconds
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification email sent!')),
      );
      _startResendCooldown(); // Start the resend cooldown timer
    }
  }

  void _startResendCooldown() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--; // Decrease countdown by 1 each second
        });
      } else {
        timer.cancel();
        setState(() {
          _canResendEmail = true; // Enable resend button after cooldown
        });
      }
    });
  }
  void handleLogoutTap() {
    print('Logout tapped');
    _signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const Signinscreen()),
          (Route<dynamic> route) => false,
    );
  }
  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Signed out successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error signing out: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
  Future<void> _checkEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload(); // Reload user to get the latest information
      user = _auth.currentUser; // Refresh user

      if (user!.emailVerified) {
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot sallerDoc = await _firestore.collection('saller').doc(user.uid).get();

        if (userDoc.exists) {
          _showFloatingSnackBar('Sign-in successful!', Colors.green);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BottomTabs()),
                (Route<dynamic> route) => false,
          );
        } else if (sallerDoc.exists) {
          _showFloatingSnackBar('Sign-in successful!', Colors.green);
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const sallerBottomTabs()),
                (Route<dynamic> route) => false,
          );
        } else {
          _showFloatingSnackBar('User not found.', Colors.red);
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
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Your Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Please verify your email address. We have sent you a verification email.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: width / 0.9,
              child: ElevatedButton(
                onPressed: _canResendEmail ? _sendVerificationEmail : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                ),
                child: Text(
                  _canResendEmail ? 'Resend Verification Email' : 'Resend in $_countdown seconds',
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            const SizedBox(height: 100),
            SizedBox(
              width: width / 03,
              child: ElevatedButton(
                onPressed: handleLogoutTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.exit_to_app,color: Colors.white,),
                    Text(
                      "Logout",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            /*Container(
              width: width / 0.9,
              child: ElevatedButton(
                onPressed: () async {
                  await _checkEmailVerification();
                },
                child: Text('Check Verification Status', style: TextStyle(color: Colors.black)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                ),
              ),
            ),*/
          ],
        ),
      ),
    );
  }
}
