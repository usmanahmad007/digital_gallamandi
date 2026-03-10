import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zrai_mart/UI/splashScreen/consentScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(
      const Duration(seconds: 3), // Adjust the time as needed
          () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Consentscreen()), // Replace with your actual main screen
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final height=MediaQuery.of(context).size.height;
    final width=MediaQuery.of(context).size.width;
    return Scaffold(
      body: Center(child: Image.asset("assets/img_1.png",width: 200,height: 200,)),
    );
  }
}
