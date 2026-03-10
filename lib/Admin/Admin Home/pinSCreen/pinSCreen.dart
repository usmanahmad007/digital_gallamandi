import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zrai_mart/Admin/Admin%20Home/AdminBottomTabs/AdminBottomTabs.dart';
import 'dart:async';


class PinCScreen extends StatefulWidget {
  const PinCScreen({super.key});

  @override
  _PinCScreenState createState() => _PinCScreenState();
}

class _PinCScreenState extends State<PinCScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  int _attempts = 0;
  int _lockDuration = 0; // Lock duration in seconds
  Timer? _lockTimer;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockTimer(int seconds) {
    setState(() {
      _lockDuration = seconds;
    });
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_lockDuration > 0) {
          _lockDuration--;
        } else {
          _lockTimer?.cancel();
        }
      });
    });
  }

  void _submitPin() {
    if (_lockDuration > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Too many attempts. Try again in $_lockDuration seconds.')),
      );
      return;
    }

    final pin = _pinController.text;
    if (pin == '123456') { // Replace with your validation logic
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context)=>const AdminBottomTabs()), (route)=>false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN Verified Successfully!')),
      );
      setState(() {
        _attempts = 0;
      });
    } else {
      setState(() {
        _attempts++;
      });

      if (_attempts == 3) {
        _startLockTimer(60); // 1-minute lock after 3 wrong attempts
      } else if (_attempts == 6) {
        _startLockTimer(1800); // 30-minute lock after 6 wrong attempts
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid PIN. Attempts left: ${3 - (_attempts % 3)}')),
      );
    }

    _pinController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade800, Colors.yellow.shade300],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Admin PIN',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20.0),
                  // PIN input field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: TextField(
                      controller: _pinController,
                      focusNode: _pinFocusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24.0,
                        letterSpacing: 16.0,
                      ),
                      enabled: _lockDuration == 0,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        counterText: '',
                        hintText: '******',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  if (_lockDuration > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Locked for $_lockDuration seconds',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 20.0),
                  // Login button
                  ElevatedButton(
                    onPressed: _submitPin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 12.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      backgroundColor: Colors.blue.shade900,
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 18.0,
                        color: Colors.white,
                      ),
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