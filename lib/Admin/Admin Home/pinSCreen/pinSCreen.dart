import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:zrai_mart/Admin/Admin%20Home/AdminBottomTabs/AdminBottomTabs.dart';

class PinCScreen extends StatefulWidget {
  const PinCScreen({super.key});

  @override
  _PinCScreenState createState() => _PinCScreenState();
}

class _PinCScreenState extends State<PinCScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _pinFocusNode = FocusNode();
  int _attempts = 0;
  int _lockDuration = 0;
  Timer? _lockTimer;

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocusNode.dispose();
    _lockTimer?.cancel();
    super.dispose();
  }

  void _startLockTimer(int seconds) {
    setState(() => _lockDuration = seconds);
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
    if (_lockDuration > 0) return;

    final pin = _pinController.text;
    if (pin == '123456') {
      // Success logic...
      Navigator.push(context, MaterialPageRoute(builder: (context)=>const AdminBottomTabs()),);

      setState(() => _attempts = 0);
    } else {
      setState(() => _attempts++);
      if (_attempts >= 3) _startLockTimer(_attempts == 3 ? 60 : 1800);
      _pinController.clear();
      HapticFeedback.vibrate(); // Feedback for wrong PIN
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF1B5E20), const Color(0xFF002300)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    size: 60, color: Colors.white),
              ),
              const SizedBox(height: 24),
              const Text(
                'ADMIN ACCESS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _lockDuration > 0
                    ? "Security Lock Active"
                    : "Enter your 6-digit security PIN",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 40),

              // PIN Display Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Hidden TextField to handle input
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _pinController,
                        focusNode: _pinFocusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        onChanged: (val) {
                          if (val.length == 6) _submitPin();
                          setState(() {});
                        },
                      ),
                    ),
                    // Visual Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(6, (index) {
                        bool isFilled = _pinController.text.length > index;
                        return Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 2),
                            color: isFilled ? Colors.white : Colors.transparent,
                            boxShadow: isFilled ? [
                              BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 10)
                            ] : [],
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Lock Timer UI
              if (_lockDuration > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Try again in $_lockDuration s',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                TextButton(
                  onPressed: () => _pinFocusNode.requestFocus(),
                  child: const Text("Open Keyboard",
                      style: TextStyle(color: Colors.white54)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}