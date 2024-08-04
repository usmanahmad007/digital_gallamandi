import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zrai_mart/UI/SignupScreen.dart';
import 'package:zrai_mart/UI/signInScreen.dart';
import '../saller center/sallerbottomTabs.dart';
import 'EmailVerificationScreen.dart';
import 'bottomTabs.dart';

class Consentscreen extends StatefulWidget {
  const Consentscreen({super.key});

  @override
  State<Consentscreen> createState() => _ConsentscreenState();
}

class _ConsentscreenState extends State<Consentscreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  void _showFloatingSnackBar(BuildContext context, String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 20.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );

    // Show the snackbar
    overlay?.insert(overlayEntry);

    // Remove the snackbar after a duration
    Future.delayed(Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }


  Future<void> _checkLoginStatus() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        DocumentSnapshot sallerDoc =
            await _firestore.collection('saller').doc(user.uid).get();
        if (user.emailVerified) {
          if (userDoc.exists) {
            Fluttertoast.showToast(msg: "Sign-in successful!");
            //_showFloatingSnackBar(context,'Sign-in successful!', Colors.green);
            Timer(
              Duration(seconds: 3),
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => BottomTabs()),
              ),
            );
          } else if (sallerDoc.exists) {
            Fluttertoast.showToast(msg: "Sign-in successful!");

            _showFloatingSnackBar(context,'Sign-in successful!', Colors.green);
            Timer(
              const Duration(seconds: 3),
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => sallerBottomTabs()),
              ),
            );
          } else {
            Fluttertoast.showToast(msg: "User not found!");

            // _showFloatingSnackBar(context,'User not found!', Colors.red);
            Timer(
              Duration(seconds: 3),
              () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => Signinscreen()),
              ),
            );
          }
        } else {
          Fluttertoast.showToast(msg: "your email is not verified!");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EmailVerificationScreen()),
          );
         // _showFloatingSnackBar(context,'your email is not verified!', Colors.red);

        }
      } else {
        Timer(
          Duration(seconds: 3),
          () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Signinscreen()),
          ),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: "An error occurred: ${e.toString()}");

     // _showFloatingSnackBar(context,'An error occurred: ${e.toString()}', Colors.red);
      _delayedCheckLoginStatus();
      // Optionally, log the error for further analysis
      print('Error checking login status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text1 = "The best crops e-commerce & online Store";
    final text2 = "App of the century for your need!";
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "assets/img.png",
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: CupertinoActivityIndicator(
              color: Colors.white,
              radius: 20,
            ),
          ),
          Positioned(
            top: height / 1.7,
            left: 20,
            bottom: 20,
            child: Column(
              children: [
                Text(
                  "Welcome to",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: height / 1.55,
            left: 20,
            bottom: 20,
            child: Text(
              "Digital Galla\nMandi",
              style: TextStyle(
                color: Colors.green,
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: height / 1.1,
            left: 20,
            bottom: 20,
            child: Text(
              text1,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: height / 1.15,
            left: 20,
            bottom: 20,
            child: Text(
              text2,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _delayedCheckLoginStatus() {
    Timer(
      Duration(seconds: 10),
      () {
        _checkLoginStatus();
      },
    );
  }
}
