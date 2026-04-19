import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zrai_mart/UI/auth/ForgotPasswordScreen.dart';
import 'package:zrai_mart/UI/auth/SignupScreen.dart';
import 'package:zrai_mart/UI/bottomTabs/bottomTabs.dart';
import 'package:zrai_mart/saller%20center/storeView/StooreSettingcreen.dart';

import '../../Admin/Admin Home/pinSCreen/pinSCreen.dart';
import '../../app_colors.dart';
import '../../saller center/bottomTabs/sallerbottomTabs.dart';
import 'EmailVerificationScreen.dart';
// Import your color file here
// import 'package:zrai_mart/utils/app_colors.dart';

class Signinscreen extends StatefulWidget {
  const Signinscreen({super.key});

  @override
  State<Signinscreen> createState() => _SigninscreenState();
}

class _SigninscreenState extends State<Signinscreen> {
  // --- BACKEND LOGIC (NO CHANGES) ---
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isPasswordVisible = false;
  bool isLoading = false;

  void _togglePasswordVisibility() {
    setState(() => _isPasswordVisible = !_isPasswordVisible);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => isLoading = true);
      try {
        UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        User? user = userCredential.user;

        if (user != null) {
          if (!user.emailVerified) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const EmailVerificationScreen()));
            return;
          }

          DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
          DocumentSnapshot sallerDoc = await _firestore.collection('saller').doc(user.uid).get();

          if (userDoc.exists) {
            Fluttertoast.showToast(msg: 'Sign-in successful!');
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const BottomTabs()), (route) => false);
          } else if (sallerDoc.exists) {
            var sellerData = sallerDoc.data() as Map<String, dynamic>? ?? {};

            // --- CHECK FLAG ---
            bool hasSetupStore = sellerData['hasSetupStore'] ?? false;

            if (!hasSetupStore) {
              Fluttertoast.showToast(msg: 'Please complete your store setup');
              // Force user to the setup screen
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const StoreSettingsScreen()),
                      (route) => false
              );
            } else {
              Fluttertoast.showToast(msg: 'Sign-in successful!');
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const sallerBottomTabs()),
                      (route) => false
              );
            }
          } else {
            Fluttertoast.showToast(msg: 'User not found');
          }
        }
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: e.message ?? "Sign-in failed");
      }
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background circle for a modern agricultural feel
          Positioned(
            top: -50,
            right: -50,
            child: CircleAvatar(
              radius: 130,
              backgroundColor: AppColors.primaryGreen.withOpacity(0.08),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  // Centered Logo
                  GestureDetector(
                    onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>PinCScreen())),
                    child: Center(
                      child: Image.asset("assets/img_1.png", height: 160),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    "Welcome to Mandi",
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark
                    ),
                  ),
                  const Text(
                    "Sign in to start trading",
                    style: TextStyle(fontSize: 16, color: AppColors.textGrey),
                  ),
                  const SizedBox(height: 35),

                  // Email Field
                  _buildInputField(
                    controller: _emailController,
                    hint: "Email Address",
                    icon: Icons.email_outlined,
                    validator: (value) => (value == null || !value.contains('@')) ? 'Invalid email' : null,
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  _buildInputField(
                    controller: _passwordController,
                    hint: "Password",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
                  ),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                      child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w600)
                      ),
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Dynamic Button / Loading State
                  isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen))
                      : SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                          "Sign In",
                          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Bottom Navigation Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Need an account? ", style: TextStyle(color: AppColors.textGrey)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const Signupscreen())),
                        child: const Text(
                            "Register",
                            style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reusable Input Field Method
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword && !_isPasswordVisible,
        validator: validator,
        cursorColor: AppColors.primaryGreen,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.primaryGreen, size: 22),
          suffixIcon: isPassword
              ? IconButton(
              icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: AppColors.textGrey, size: 20),
              onPressed: _togglePasswordVisibility
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        ),
      ),
    );
  }
}